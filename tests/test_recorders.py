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

import ndr_server
import psycopg2

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
TEST_CONFIG = THIS_DIR + "/test_config.yml"


class TestSites(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Now load a global config object so the DB connection is open
        cls._nsc = ndr_server.Config(logging.NullHandler(), TEST_CONFIG)
        cls._db_connection = cls._nsc.database.get_connection()

        # For this specific test, we need to create a few test objects
        cls._test_org = ndr_server.Organization.create(
            cls._nsc, "Testing Recorders Org", db_conn=cls._db_connection)
        cls._test_site = ndr_server.Site.create(
            cls._nsc, cls._test_org, "Testing Recorders Site", db_conn=cls._db_connection)

    @classmethod
    def tearDownClass(cls):
        cls._db_connection.rollback()
        cls._nsc.database.close()

    def test_create(self):
        '''Create an recorder and make sure the procedural SQL don't go bang'''
        ndr_server.Recorder.create(self._nsc, self._test_site, "Test Recorder", "ndr_test",
                                   db_conn=self._db_connection)

    def test_read_by_id(self):
        '''We need to create a new ID so we know the pg_id from the insert and can read it back'''
        recorder_orig = ndr_server.Recorder.create(
            self._nsc, self._test_site, "Test Recorder 2", "ndr_test2",
            db_conn=self._db_connection)

        recorder_read = ndr_server.Recorder.read_by_id(
            self._nsc, recorder_orig.pg_id, db_conn=self._db_connection)

        self.assertEqual(recorder_orig, recorder_read)

    def test_read_by_hostname(self):
        '''Once again, we test a CRUD operation by hostname'''
        recorder_orig = ndr_server.Recorder.create(
            self._nsc, self._test_site, "Test Recorder 2", "ndr_test3",
            db_conn=self._db_connection)

        recorder_read = ndr_server.Recorder.read_by_hostname(
            self._nsc, "ndr_test3", db_conn=self._db_connection)

        self.assertEqual(recorder_orig, recorder_read)

    def test_expect_on_bad_read(self):
        '''Tests database exception throwing'''

        # Create a new DB connection for this as it will be reset
        db2 = self._nsc.database.get_connection()
        self.assertRaises(psycopg2.InternalError,
                          ndr_server.Recorder.read_by_id, self._nsc, 10000,
                          db_conn=db2)
        db2.close()

    def test_updating_recorder_sw_attributions(self):
        '''Confirms that we can properly update and set the version of SW the recorder is running'''
        recorder = ndr_server.Recorder.create(
            self._nsc, self._test_site, "Test Recorder SW revision", "ndr_sw",
            db_conn=self._db_connection
        )

        recorder.set_recorder_sw_revision(12345678, "test", self._db_connection)

        # Now read back that recorder, and see if we can get the magic
        recorder_read = ndr_server.Recorder.read_by_id(self._nsc,
                                                       recorder.pg_id,
                                                       db_conn=self._db_connection)

        self.assertEqual(recorder_read.image_type, "test")
        self.assertEqual(recorder_read.image_build_date, 12345678)

if __name__ == '__main__':
    unittest.main()
