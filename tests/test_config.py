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

import psycopg2
import ndr_server

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
TEST_CONFIG = THIS_DIR + "/test_config.yml"

class TestOrganizations(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Now load a global config object so the DB connection is open
        cls._nsc = ndr_server.Config(logging.NullHandler(), TEST_CONFIG)

        # For this specific test, we need to create a few test objects
        cls._test_org = ndr_server.Organization.create(
            cls._nsc, "Testing Config Org")
        cls._test_site = ndr_server.Site.create(
            cls._nsc, cls._test_org, "Testing Config Site")

        # Make a couple of test recorders
        ndr_server.Recorder.create(
            cls._nsc, cls._test_site, "Config Test Recorder 1", "cfg-test1"
        )
        ndr_server.Recorder.create(
            cls._nsc, cls._test_site, "Config Test Recorder 2", "cfg-test2"
        )
        ndr_server.Recorder.create(
            cls._nsc, cls._test_site, "Config Test Recorder 3", "cfg-test3"
        )

    def test_uucp_config(self):
        '''Tests updating of the UUCP configuration file'''

        self._nsc.update_uucp_sys_file()
