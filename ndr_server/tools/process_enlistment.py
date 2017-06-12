#!/usr/bin/python3
# Copyright (C) 2017  Secured By THEM
# Original Author: Michael Casadevall <michaelc@them.com>
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

import os
import glob
import logging
import json

import psycopg2

import requests
import ndr
import ndr_server
import socket

from cryptography import x509
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.backends import default_backend


def main():
    # Do our basic setup work
    logging.basicConfig(format='%(asctime)s %(levelname)s %(message)s')
    logger = logging.getLogger(name=__name__)
    logger.setLevel(logging.DEBUG)

    # We need both configs
    ncc = ndr.Config("/etc/ndr/config.yml") # NDR Client Config
    nsc = ndr_server.Config(
        logger, "/etc/ndr/ndr_server.yml")

    # Iterate through all the files in the enrollment directory
    for enrollment_file in glob.glob(nsc.enrollment_directory + "/*"):
        # We should expect to see a CERTIFICATE REQUEST from a machine that wishes to be
        # enrolled. Unlike normal ingest messages, enrollment requests are not signed.

        with open(enrollment_file, "r") as f:
            yaml_contents = f.read()

        ingest_msg = ndr.IngestMessage(ncc)
        ingest_msg.load_from_yaml(yaml_contents)

        if ingest_msg.message_type != ndr.IngestMessageTypes.CERTIFICATE_REQUEST:
            print(enrollment_file, "is not a CERTIFICATE_REQUEST. Ignoring ...")

        csr_request = ndr.CertificateRequest(ncc)
        csr_request.from_message(ingest_msg)

        # Get the interesting bits from the certificate
        cert = x509.load_pem_x509_csr(
            bytes(csr_request.csr, 'utf-8'), default_backend())

        common_name = cert.subject.get_attributes_for_oid(
            x509.NameOID.COMMON_NAME)[0].value
        orgnaization_name = cert.subject.get_attributes_for_oid(
            x509.NameOID.ORGANIZATION_NAME)[0].value
        ou_name = cert.subject.get_attributes_for_oid(
            x509.NameOID.ORGANIZATIONAL_UNIT_NAME)[0].value
        human_name = cert.subject.get_attributes_for_oid(
            x509.NameOID.PSEUDONYM)[0].value

        # Try to get the organization. If failure, it doesn't exist
        try:
            organization = ndr_server.Organization.read_by_name(nsc, orgnaization_name)
        except psycopg2.Error:
            organization = None

        site = None
        if organization is not None:
            try:
                site = ndr_server.Site.read_by_name(nsc, ou_name)
            except psycopg2.Error:
                site = None

        print("Recorder Enlistment Request")
        print("Organization: ", orgnaization_name)
        print("OU/Site: ", ou_name)
        print("Human Name: ", human_name)
        print("Common Name: ", common_name)
        print()

        if organization is None:
            print("WARNING: Organization", orgnaization_name, "does not exist.")
            print("         It will be created if recorder is enrolled")
            print()
        if site is None:
            print("WARNING: Site", ou_name, "does not exist.")
            print("         It will be created if recorder is enrolled")
            print()

        confirmation = input("Enroll recorder? [N/y/s] ")

        if not confirmation or confirmation.lower()[0] == 's':
            print("Skipping to next ...")
            continue

        if not confirmation or confirmation.lower()[0] != 'y':
            print("Deleting request ...")
            print("")

            os.remove(enrollment_file)
            continue # Go to the next

        local_install = False

        if common_name == socket.gethostname():
            local = input("Certificate CN matches local hostname. Install certificates locally for server [Y/n]?")
            if not local or local.lower()[0] != 'n':
                print("Checking we can write local certificates ...")

                if os.geteuid() != 0:
                    print("Not root, bailing out")
                    return
                local_install = True

        # Start a transaction and create the organization and site if needed
        db_connection = nsc.database.get_connection()
        cursor = db_connection.cursor()

        if organization is None:
            print("Creating organization", orgnaization_name)    
            organization = ndr_server.Organization.create(nsc, orgnaization_name, db_connection)

        if site is None:
            print("Creating site", ou_name)
            site = ndr_server.Site.create(nsc, organization, ou_name, db_connection)

        # We try to create the recorder before the certificate in case of a CN collision
        # If the CN collides, this will fail, and the transaction will rollback
        print("Creating recorder ...")
        recorder = ndr_server.Recorder.create(nsc, site, human_name, common_name, db_connection)

        print("Attempting to sign CSR ...")

        # Create a signing request for CFSSL
        cfssl_sign = {}
        cfssl_sign['certificate_request'] = csr_request.csr
        cfssl_sign['profile'] = "recorder"

        # CFSSL's bundle feature could be used to get the full certificate chain, but
        # it duplicates the signed certificate in the bundle which is annoying because OpenSSL
        # requires the chain to be in a seperate file *so* we'll just grab the signed certificate
        # and grab the intermediate from the save directory

        cfssl_response = requests.post("http://127.0.0.1:8888/api/v1/cfssl/sign",
                                       json.dumps(cfssl_sign))

        if cfssl_response.status_code != 200:
            print("Signing failure!")
            print("Response was", cfssl_response.text)
            print("Bailing out")
            return

        print("Got a signed certificate from CFSSL")
        cfssl_json = cfssl_response.json()

        if local_install:
            print("Installing the certificate bundle locally")
            with open(ncc.ssl_certfile, "w") as f:
                f.write(cfssl_json['result']['certificate'])
                db_connection.commit()
                print("Database updated!")
        else:
            # Create a new signed message and send it back down the pipe
            signed_csr_message = ndr.CertificateRequest(ncc)

            # Populate the certificate chain and send it back
            signed_csr_message.certificate = cfssl_json['result']['certificate']

            # Load the intermediate certificate chain from the filesystem
            with open(ncc.ssl_bundle, 'r') as f:
                signed_csr_message.certificate_chain = f.read()

            # Strictly speaking, we probably don't need to include the root certificate but it is
            # handy for testing and debugging
            with open(ncc.ssl_cafile, 'r') as f:
                signed_csr_message.root_certificate = f.read()

            signed_csr_message.destination = common_name
            signed_csr_message.upload_method = 'uux'
            signed_csr_message.sign_report()
            signed_csr_message.load_into_queue()

        print("Removing", enrollment_file)
        os.remove(enrollment_file)

    print ("Done processing enrollments")
    return

if __name__ == '__main__':
    main()
