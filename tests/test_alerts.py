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
import tempfile

import os
import shutil
import logging

import ndr
import ndr_server

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
TEST_CONFIG = THIS_DIR + "/test_config.yml"
ALERT_MSG = THIS_DIR + "/data/ingest/alert_msg.yml"

class TestAlerts(unittest.TestCase):
    '''Test alert behaviors'''
    def setUp(self):
        logging.getLogger().addHandler(logging.NullHandler())
        # Now load a global config object so the DB connection is open
        self._nsc = ndr_server.Config(logging.getLogger(), TEST_CONFIG)

        # We need to process test messages, so override the base directory for
        # this test
        self._db_connection = self._nsc.database.get_connection()

        # For this specific test, we need to create a few test objects
        self._test_org = ndr_server.Organization.create(
            self._nsc, "Network Scan Recorders Org", db_conn=self._db_connection)
        self._test_site = ndr_server.Site.create(
            self._nsc, self._test_org, "Network Scan Recorders Site", db_conn=self._db_connection)
        self._recorder = ndr_server.Recorder.create(
            self._nsc, self._test_site, "Test Recorder", "ndr_test_ingest",
            db_conn=self._db_connection)

        # We need a test file contact
        file_descriptor, self._test_contact = tempfile.mkstemp()
        os.close(file_descriptor) # Don't need to write anything to it

        ndr_server.Contact.create(
            self._nsc, self._test_org, "file", self._test_contact,
            db_conn=self._db_connection)

    def tearDown(self):
        self._db_connection.rollback()
        self._nsc.database.close()
        os.remove(self._test_contact)

    def test_alert_msg(self):
        '''Tests that the alert msg template is sane'''

        file_contents = ""
        with open(ALERT_MSG, 'r') as scanfile:
            file_contents = scanfile.read()

        ingest_daemon = ndr_server.IngestServer(self._nsc)
        ingest_daemon.process_ingest_message(self._db_connection, self._recorder, file_contents)

        with open(self._test_contact, 'r') as f:
            alert_contents = f.read()

        # Make sure the test message is NOT empty
        self.assertNotEqual(alert_contents, "")

        # Make sure the important parts are there
        self.assertIn("[1:42130:1] BLACKLIST DNS request for known malware domain", alert_contents)
