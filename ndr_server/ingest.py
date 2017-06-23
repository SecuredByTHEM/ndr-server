# Copyright (C) 2017  Secured By THEM
# Original Author: Michael Casadevall <mcasadevall@them.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

'''Core functionality relating to ingesting server messages'''

import os
import shutil
import sys
import glob
import time
import json

import subprocess

import ndr
import ndr_server
import tempfile

import psycopg2

from cryptography import x509
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.backends import default_backend

INGEST_VERSION = '0.0.3'


class IngestServer():
    '''Processes files for ingest'''

    def __init__(self, config):
        self.config = config
        self.logger = config.logger

    def init_processing_directory(self, name, path):
        '''Creates processing directories for ingest'''
        if os.path.isdir(path) is False:
            self.logger.warn("creating %s directory: %s",
                             name,
                             path)
            os.makedirs(path)
        else:
            self.logger.debug("%s directory: %s", name, path)

    def prep_ingest_directories(self):
        '''Creates all the ingest directories if necessary'''
        self.init_processing_directory(
            "base", self.config.base_directory)
        self.init_processing_directory(
            "accepted", self.config.accepted_directory)
        self.init_processing_directory(
            "incoming", self.config.incoming_directory)
        self.init_processing_directory(
            "rejected", self.config.reject_directory)
        self.init_processing_directory(
            "error", self.config.error_directory)
        self.init_processing_directory(
            "enrollment", self.config.enrollment_directory
        )

    def process_ingest_message(self, db_connection, recorder, decoded_message):
        '''Processes an ingest message as per the main processing loop'''

        cursor = db_connection.cursor()

        # Attempt to deserialize the YAML file into its base
        # format
        message = ndr.IngestMessage()
        message.load_from_yaml(decoded_message)

        self.logger.info(
            "message generated at %s", message.generated_at)

        # Create the upload log
        cursor.callproc("ingest.create_upload_log", [recorder.pg_id,
                                                     message.message_type.value,
                                                     message.generated_at])
        log_id = cursor.fetchone()[0]

        if message.message_type == ndr.IngestMessageTypes.TEST_ALERT:
            # Get the organization so we can determine what emails we need to send
            site = recorder.get_site(db_connection)
            organization = site.get_organization(db_connection)
            alert_contacts = organization.get_contacts()

            test_alert_msg = ndr_server.TestAlertTemplate(
                organization, site, recorder, message.generated_at
            )

            for contact in alert_contacts:
                contact.send_message(
                    test_alert_msg.subject(), test_alert_msg.prepped_message()
                )

        elif message.message_type == ndr.IngestMessageTypes.NMAP_SCAN:
            # Deserialize the scan back into a usable object
            storable_scan = ndr.NmapScan()
            storable_scan.from_message(message)

            scan_json = json.dumps(storable_scan.to_dict())
            cursor.callproc("network_scan.import_scan", [log_id, scan_json])

        elif message.message_type == ndr.IngestMessageTypes.SYSLOG_UPLOAD:
            syslog = ndr.SyslogUploadMessage().from_message(
                message)
            for log_entry in syslog:
                cursor.callproc("ingest.insert_syslog_entry",
                                [log_id,
                                 recorder.pg_id,
                                 log_entry.timestamp,
                                 log_entry.program,
                                 log_entry.priority.value,
                                 log_entry.pid,
                                 log_entry.host,
                                 log_entry.facility.value,
                                 log_entry.message])

    def message_processing_loop(self):
        '''Runs the main processing loop for messages'''
        for file in glob.glob(self.config.incoming_directory + "/*"):
            self.logger.info("processing %s", file)

            db_connection = self.config.database.get_connection()

            try:
                # We need a temporary file to get the signer PEM
                msg_fd, signer_pem = tempfile.mkstemp()
                os.close(msg_fd) # Don't need to write anything to it

                # We need to validate the S/MIME signatures coming up the pipe from the
                # recorder. However, as of writing, there's no good way to do this in Py3
                # so we'll shell out to OpenSSL to verify it, and extract a X509 cert we
                # can look at

                ossl_verify_cmd = ["openssl", "smime", "-verify",
                                   "-in", file, "-CAfile", self.config.smime_ca, "-text",
                                   "-signer", signer_pem]

                ossl_verify_proc = subprocess.run(
                    args=ossl_verify_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                    check=False)

                if ossl_verify_proc.returncode != 0:
                    self.logger.warn(
                        "rejecting %s: %s", file, str(ossl_verify_proc.stderr))
                    # punt you off to the reject folder
                    shutil.move(file, self.config.reject_directory)
                    continue

                self.logger.info("passed openssl S/MIME verify")
                decoded_message = ossl_verify_proc.stdout

                # Unfortunately, we're not done yet. We need to read in the X509 signing
                # certificate to get the commonName and fingerprints. As of writing, there isn't
                # a Python library that can successfully read PKCS7 certificate packs, so we
                # need to run the message through openssl a few times to get the X509
                # certificate
                #
                # As there's no good way to fish out just the signer certificate in Python,
                # we'll used the signer option on openssl to grab it and then read it in
                # after the fact

                self.logger.debug("checking %s", signer_pem)
                with open(signer_pem, 'rb') as x509_signer:
                    # NOW we can use cryptography to read the x509 certificates
                    cert = x509.load_pem_x509_certificate(
                        x509_signer.read(), default_backend())

                    common_name = cert.subject.get_attributes_for_oid(
                        x509.NameOID.COMMON_NAME)[0].value

                    self.logger.info("common name: %s", common_name)

                os.remove(signer_pem)

                recorder = ndr_server.Recorder.read_by_hostname(
                    self.config, common_name, db_connection)

                self.logger.info("processing %s for recorder %s (%d) ",
                                 file, recorder.human_name, recorder.pg_id)

                # CAST YE INTO THY DATABASE
                self.process_ingest_message(db_connection, recorder, decoded_message)

                db_connection.commit()

                shutil.move(
                    file, self.config.accepted_directory)

            # Handle out the most common error cases
            except psycopg2.Error as exception:
                self.logger.error(
                    "PostgreSQL error: %s", exception.pgerror)
                db_connection.rollback()

                self.logger.error(
                    "error %s: %s", file, sys.exc_info()[0])
                shutil.move(file, self.config.error_directory)

            except:
                self.logger.error(
                    "error %s: %s", file, sys.exc_info()[0])
                shutil.move(file, self.config.error_directory)
                raise
            finally:
                self.config.database.return_connection(db_connection)

    def start_server(self):
        '''Does prep work and starts main event loop'''
        self.logger.info("=== ingest %s starting up ===", INGEST_VERSION)
        self.prep_ingest_directories()

        # Main event loop

        while True:
            self.message_processing_loop()
            time.sleep(5)
