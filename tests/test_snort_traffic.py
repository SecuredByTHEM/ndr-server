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
import ipaddress

import geoip2
import ndr_server

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
TEST_CONFIG = THIS_DIR + "/test_config.yml"
SNORT_TRAFFIC_LOG = THIS_DIR + "/data/ingest/snort_traffic_log.yml"

LONG_SINCE_PERIOD = 157680000 # 5 years - since reports are based on generate date

def check_if_can_open_geoip_db():
    nsc = ndr_server.Config(logging.getLogger(), TEST_CONFIG)
    try:
        geoip_db = geoip2.database.Reader(nsc.geoip_db)
    except:
        return False

    return True

@unittest.skipUnless(check_if_can_open_geoip_db(), "no geoip DB")
class TestTrafficReporting(unittest.TestCase):
    '''Tests importing and reporting of traffic from snort'''

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

        # We need a test file contact
        file_descriptor, cls._test_contact = tempfile.mkstemp()
        os.close(file_descriptor) # Don't need to write anything to it

        ndr_server.Contact.create(
            cls._nsc, cls._test_org, "file", cls._test_contact,
            db_conn=cls._db_connection)

    @classmethod
    def tearDownClass(cls):
        cls._db_connection.rollback()
        cls._nsc.database.close()
        shutil.rmtree(cls._testdir)
        os.remove(cls._test_contact)

    def ingest_file(self, filename):
        '''Simply feeds in the response for an ingest test'''
        file_contents = ""
        with open(filename, 'r') as scanfile:
            file_contents = scanfile.read()

        ingest_daemon = ndr_server.IngestServer(self._nsc)

        ingest_daemon.process_ingest_message(self._db_connection, self._recorder, file_contents)

    def test_load_from_database(self):
        '''Tests getting basic JSON information from a report from the database'''

        # Ingest a log so that we can pull a traffic report
        self.ingest_file(SNORT_TRAFFIC_LOG)

        traffic_report = ndr_server.SnortTrafficReport.pull_report_for_time_interval(
            self._nsc, self._test_site, LONG_SINCE_PERIOD, db_conn=self._db_connection)
        self.assertEqual(len(traffic_report.traffic_dicts), 3)

    def test_process_dicts(self):
        '''Tests getting basic JSON information from a report from the database'''

        # Ingest a log so that we can pull a traffic report
        self.ingest_file(SNORT_TRAFFIC_LOG)

        traffic_report = ndr_server.SnortTrafficReport.pull_report_for_time_interval(
            self._nsc, self._test_site, LONG_SINCE_PERIOD, db_conn=self._db_connection)

        traffic_report.process_dicts()

        # The test data was specificly set do both the IPv4/IPv6 traffic is in Dallas
        self.assertEqual(len(traffic_report.traffic_dicts), 2)

        for traffic_dict in traffic_report.traffic_dicts:
            self.assertEqual(traffic_dict['country'], 'United States')
            self.assertEqual(traffic_dict['subdivision'], 'Texas')
            self.assertEqual(traffic_dict['city'], 'Dallas')

    def test_generate_statistics(self):
        '''Tests generation of statistics of SNORT traffic'''
        self.ingest_file(SNORT_TRAFFIC_LOG)

        traffic_report = ndr_server.SnortTrafficReport.pull_report_for_time_interval(
            self._nsc, self._test_site, LONG_SINCE_PERIOD, db_conn=self._db_connection)

        traffic_report.process_dicts()
        traffic_report.generate_statistics()
        self.assertIn("United States", traffic_report.statistics_dicts)

    def test_email_report(self):
        '''Tests generation of email reports and such'''
        self.ingest_file(SNORT_TRAFFIC_LOG)

        traffic_report = ndr_server.SnortTrafficReport.pull_report_for_time_interval(
            self._nsc, self._test_site, LONG_SINCE_PERIOD, db_conn=self._db_connection)

        traffic_report.process_dicts()
        traffic_report.generate_statistics()

        traffic_report.generate_report_emails(send=True, db_conn=self._db_connection)

        with open(self._test_contact, 'r') as f:
            alert_email = f.read()

        self.assertIn("This is a snapshot of internet traffic broken down by destination IP", alert_email)

    def test_breakdown_by_machine(self):
        '''Tests breaking down traffic by machine'''
        self.ingest_file(SNORT_TRAFFIC_LOG)

        traffic_report = ndr_server.SnortTrafficReport.pull_report_for_time_interval(
            self._nsc, self._test_site, LONG_SINCE_PERIOD, db_conn=self._db_connection)
        traffic_report.process_dicts()
        local_breakdown = traffic_report.breakdown_traffic_by_internal_ip()

        key = ipaddress.ip_address("192.168.2.2")
        self.assertEqual(local_breakdown[key]['country']['United States']['rxpackets'], 18000)
        self.assertEqual(local_breakdown[key]['country']['United States']['txpackets'], 96)