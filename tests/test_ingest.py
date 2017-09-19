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

import ndr_server
import tests.util

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
TEST_CONFIG = THIS_DIR + "/test_config.yml"
NMAP_ARP_SCAN = THIS_DIR + "/data/ingest/nmap_arp_scan.yml"
SYSLOG_SCAN = THIS_DIR + "/data/ingest/syslog_upload.yml"
TEST_ALERT_MESSAGE = THIS_DIR + "/data/ingest/test_alert.yml"
SNORT_TRAFFIC_LOG = THIS_DIR + "/data/ingest/snort_traffic_log.yml"
TRAFFIC_REPORT_LOG = THIS_DIR + "/data/ingest/traffic_report.yml"
ALERT_MSG_LOG = THIS_DIR + "/data/ingest/alert_msg.yml"
STATUS_MSG = THIS_DIR + "/data/ingest/status.yml"

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
            cls._nsc, "Ingest Recorders Org", db_conn=cls._db_connection)
        cls._test_site = ndr_server.Site.create(
            cls._nsc, cls._test_org, "Ingest Recorders Site", db_conn=cls._db_connection)
        cls._recorder = ndr_server.Recorder.create(
            cls._nsc, cls._test_site, "Test Recorder", "ndr_test_ingest",
            db_conn=cls._db_connection)

    @classmethod
    def tearDownClass(cls):
        cls._db_connection.rollback()
        cls._nsc.database.close()
        shutil.rmtree(cls._testdir)

    def test_incoming_directories_creation(self):
        '''Confirms that we can successfully create the directories we need to process messages'''
        ingest_daemon = ndr_server.IngestServer(self._nsc)
        ingest_daemon.prep_ingest_directories()

        self.assertTrue(os.path.isdir(self._nsc.accepted_directory))
        self.assertTrue(os.path.isdir(self._nsc.incoming_directory))
        self.assertTrue(os.path.isdir(self._nsc.reject_directory))
        self.assertTrue(os.path.isdir(self._nsc.error_directory))
        self.assertTrue(os.path.isdir(self._nsc.enrollment_directory))

    def test_nmap_ingest(self):
        '''Tests that an NMAP scan actually goes into the database'''
        tests.util.ingest_test_file(self, NMAP_ARP_SCAN)

    def test_syslog_ingest(self):
        '''Tests that an syslog ingest actually goes into the database'''
        tests.util.ingest_test_file(self, SYSLOG_SCAN)

    def test_alert_tester(self):
        '''Tests the Alert Test Message'''
        tests.util.ingest_test_file(self, TEST_ALERT_MESSAGE)

    def test_snort_traffic_ingest(self):
        '''Tests ingesting a snort traffic report'''
        tests.util.ingest_test_file(self, SNORT_TRAFFIC_LOG)

    def test_ingesting_alert_msg(self):
        '''Tests ingesting a generic alert message'''
        tests.util.ingest_test_file(self, ALERT_MSG_LOG)

    def test_ingesting_status_msg(self):
        '''Tests ingesting a status message'''
        tests.util.ingest_test_file(self, STATUS_MSG)

    def test_ingesting_traffic_report_msg(self):
        '''Tests ingesting a traffic report'''
        tests.util.ingest_test_file(self, TRAFFIC_REPORT_LOG)

if __name__ == '__main__':
    unittest.main()
