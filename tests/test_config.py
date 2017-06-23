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

import psycopg2
import ndr_server

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
TEST_CONFIG = THIS_DIR + "/test_config.yml"

class TestConfigClass(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Now load a global config object so the DB connection is open
        cls._nsc = ndr_server.Config(logging.NullHandler(), TEST_CONFIG)
        cls._db_connection = cls._nsc.database.get_connection()

        # UUCP file is written here for comparsion
        fd, uucp_sys_test = tempfile.mkstemp()
        os.close(fd) # Don't need to write anything to it

        cls._nsc.uucp_sys_config = uucp_sys_test

        # For this specific test, we need to create a few test objects
        cls._test_org = ndr_server.Organization.create(
            cls._nsc, "Testing Config Org", db_conn=cls._db_connection)
        cls._test_site = ndr_server.Site.create(
            cls._nsc, cls._test_org, "Testing Config Site", db_conn=cls._db_connection)

        # Make a couple of test recorders
        ndr_server.Recorder.create(
            cls._nsc, cls._test_site, "Config Test Recorder 1", "cfg-test1", db_conn=cls._db_connection
        )
        ndr_server.Recorder.create(
            cls._nsc, cls._test_site, "Config Test Recorder 2", "cfg-test2", db_conn=cls._db_connection
        )
        ndr_server.Recorder.create(
            cls._nsc, cls._test_site, "Config Test Recorder 3", "cfg-test3", db_conn=cls._db_connection
        )

    @classmethod
    def tearDownClass(cls):
        cls._db_connection.rollback()

        # Delete our temporary file
        os.remove(cls._nsc.uucp_sys_config)

    def test_uucp_config(self):
        '''Tests updating of the UUCP configuration file'''

        self._nsc.update_uucp_sys_file(db_conn=self._db_connection)

        test_data = None

        with open(self._nsc.uucp_sys_config, 'r') as f:
            written_config = f.read()

            # This is horrible and hacky, but because the test can execute in any order, make sure
            # all the lines are there that we care about.
            #
            # FIXME: Refactor this to be something less horrid and hacky once we have a way to have
            # the database clean up after itself

            self.assertIn("protocol gvG", written_config)
            self.assertIn("protocol-parameter G packet-size 1024", written_config)
            self.assertIn("protocol-parameter G short-packets", written_config)
            self.assertIn("remote-receive /tmp/ndr-server/incoming /tmp/ndr-server/enrollment",
                          written_config)

            # We only assert protocol t once at the end because it appears multiple times
            self.assertIn("system cfg-test1", written_config)
            self.assertIn("system cfg-test2", written_config)
            self.assertIn("system cfg-test3", written_config)
            self.assertIn("protocol t", written_config)
