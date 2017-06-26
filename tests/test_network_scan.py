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

import unittest
import os
import logging
import tempfile
import shutil

import ndr
import ndr_server

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
TEST_CONFIG = THIS_DIR + "/test_config.yml"
NMAP_ARP_SCAN = THIS_DIR + "/data/ingest/nmap_arp_scan.yml"
SYSLOG_SCAN = THIS_DIR + "/data/ingest/syslog_upload.yml"

class TestIngests(unittest.TestCase):
    '''Tests various ingest cases'''

    @classmethod
    def setUpClass(cls):
        logging.getLogger().addHandler(logging.NullHandler())
        # Now load a global config object so the DB connection is open
        cls._nsc = ndr_server.Config(logging.getLogger(), TEST_CONFIG)

        # We need to process test messages, so override the base directory for
        # this test
        cls._testdir = tempfile.mkdtemp()
        cls._nsc.base_directory = cls._testdir
        cls._db_connection = cls._nsc.database.get_connection()

        # For this specific test, we need to create a few test objects
        cls._test_org = ndr_server.Organization.create(
            cls._nsc, "Network Scan Recorders Org", db_conn=cls._db_connection)
        cls._test_site = ndr_server.Site.create(
            cls._nsc, cls._test_org, "Network Scan Recorders Site", db_conn=cls._db_connection)
        cls._recorder = ndr_server.Recorder.create(
            cls._nsc, cls._test_site, "Test Recorder", "ndr_test_ingest",
            db_conn=cls._db_connection)

    @classmethod
    def tearDownClass(cls):
        cls._db_connection.rollback()
        cls._nsc.database.close()
        shutil.rmtree(cls._testdir)

    def load_network_scan(self, file_path):
        '''Loads a network scan'''
        with open(file_path, 'r') as yaml_msg:
            yaml_file = yaml_msg.read()

        message = ndr.IngestMessage()
        message.load_from_yaml(yaml_file)

        cursor = self._db_connection.cursor()
        cursor.callproc("ingest.create_upload_log", [self._recorder.pg_id,
                                                     message.message_type.value,
                                                     message.generated_at])
        log_id = cursor.fetchone()[0]

        net_scan = ndr_server.NetworkScan.create_from_message(self._nsc,
                                                              log_id,
                                                              message,
                                                              db_conn=self._db_connection)
        return net_scan

    def test_unknown_hosts(self):
        '''Tests that we can detect unknown hosts'''
        net_scan = self.load_network_scan(NMAP_ARP_SCAN)
        host_objs = net_scan.get_unknown_hosts_from_scan(db_conn=self._db_connection)
        self.assertEqual(len(host_objs), 4)

if __name__ == '__main__':
    unittest.main()
