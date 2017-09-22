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

'''Tests functionality related to traffic_reports'''

import unittest
import os
import logging
from datetime import datetime, timedelta

import tests.util
import ndr_server

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
TEST_CONFIG = THIS_DIR + "/test_config.yml"
TRAFFIC_REPORT_LOG = THIS_DIR + "/data/ingest/traffic_report.yml"

class TestIngests(unittest.TestCase):
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

        # We need to ingest a traffic report message so it can be used by all following stuff
        cls._ingested_test_data = False

    @classmethod
    def tearDownClass(cls):
        cls._db_connection.rollback()
        cls._nsc.database.close()

    def ingest_traffic_report(self):
        '''Hack around the fact that trying to ingest a file in the setUpClass method causes a deadlock'''
        if self._ingested_test_data is False:
            tests.util.ingest_test_file(self, TRAFFIC_REPORT_LOG)
            self._ingested_test_data = True

    def test_geoip_reporting(self):
        '''Tests loading of a status message and making sure the version information updates'''
        self.ingest_traffic_report()

        report_manager = ndr_server.TsharkTrafficReportManager(self._nsc,
                                                               self._test_site,
                                                               self._db_connection)
        report_manager.retrieve_geoip_breakdown(
            datetime.now() - timedelta(days=1),
            datetime.now(),
            self._db_connection)

    def test_machine_breakdown_reporting(self):
        '''Tests loading of a status message and making sure the version information updates'''
        self.ingest_traffic_report()

        report_manager = ndr_server.TsharkTrafficReportManager(self._nsc,
                                                               self._test_site,
                                                               self._db_connection)
        report_manager.retrieve_geoip_by_local_ip_breakdown(
            datetime.now() - timedelta(days=1),
            datetime.now(),
            self._db_connection)
