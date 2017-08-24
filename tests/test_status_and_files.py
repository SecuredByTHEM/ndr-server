#!/usr/bin/python3
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

'''Tests functionality related to status messages and file management'''

import unittest
import os
import logging
import hashlib

import ndr
import ndr_server

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
TEST_CONFIG = THIS_DIR + "/test_config.yml"
STATUS_MSG= THIS_DIR + "/data/ingest/status.yml"

class TestStatusAndFiles(unittest.TestCase):
    '''Tests various ingest cases'''

    @classmethod
    def setUpClass(cls):
        logging.getLogger().addHandler(logging.NullHandler())
        # Now load a global config object so the DB connection is open
        cls._nsc = ndr_server.Config(logging.getLogger(), TEST_CONFIG)

        # We need to process test messages, so override the base directory for
        # this test
        cls._db_connection = cls._nsc.database.get_connection()

        # For this specific test, we need to create a few test objects
        cls._test_org = ndr_server.Organization.create(
            cls._nsc, "Ingest Recorders Org", db_conn=cls._db_connection)
        cls._test_site = ndr_server.Site.create(
            cls._nsc, cls._test_org, "Ingest Recorders Site", db_conn=cls._db_connection)
        cls._recorder = ndr_server.Recorder.create(
            cls._nsc, cls._test_site, "Test Recorder", "ndr_test_status",
            db_conn=cls._db_connection)

    @classmethod
    def tearDownClass(cls):
        cls._db_connection.rollback()
        cls._nsc.database.close()

    def ingest_test_file(self, filename):
        '''Simply feeds in the response for an ingest test'''
        file_contents = ""
        with open(filename, 'r') as scanfile:
            file_contents = scanfile.read()

        ingest_daemon = ndr_server.IngestServer(self._nsc)

        ingest_daemon.process_ingest_message(self._db_connection, self._recorder, file_contents)

    def test_recorder_version_update(self):
        '''Tests loading of a status message and making sure the version information updates'''

        self.ingest_test_file(STATUS_MSG)

        recorder = ndr_server.Recorder.read_by_id(self._nsc,
                                                  self._recorder.pg_id,
                                                  db_conn=self._db_connection)
        self.assertEqual(recorder.image_build_date, 1499734693)
        self.assertEqual(recorder.image_type, 'development')

    def test_loading_file_to_file_manager(self):
        '''Tests loading a file to the file manager'''
        file_manager = self._recorder.get_file_manager(self._db_connection)

        # We'll use the configuration file as a test of this
        with open(TEST_CONFIG, 'rb') as f:
            test_data = f.read()

        # Calculate the reference SHA256 hash
        sha256_hash = hashlib.sha256(test_data).hexdigest()

        file_manager.add_or_update_file(ndr.NdrConfigurationFiles.NMAP_CONFIG,
                                        test_data,
                                        self._db_connection)

        nmap_config_file = file_manager.file_info[ndr.NdrConfigurationFiles.NMAP_CONFIG]
        self.assertEqual(nmap_config_file.file_type, ndr.NdrConfigurationFiles.NMAP_CONFIG)
        self.assertIsNone(nmap_config_file.recorder_sha256)
        self.assertEqual(nmap_config_file.expected_sha256, sha256_hash)
