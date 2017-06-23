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


class TestContacts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Now load a global config object so the DB connection is open
        cls._nsc = ndr_server.Config(logging.NullHandler(), TEST_CONFIG)
        cls._db_connection = cls._nsc.database.get_connection()

        # For this specific test, we need to create a few test objects
        cls._test_org = ndr_server.Organization.create(cls._nsc, "Test Contacts",
                                                       db_conn=cls._db_connection)

    @classmethod
    def tearDownClass(cls):
        cls._nsc.database.close()

    def test_create(self):
        '''Create an organization and make sure the procedural SQL don't go bang'''
        ndr_server.Contact.create(
            self._nsc, self._test_org, "email", "mcasadevall@them.com",
            db_conn=self._db_connection)

    def test_get_by_id(self):
        '''Tests getting contacts by ID'''
        orig_contact = ndr_server.Contact.create(
            self._nsc, self._test_org, "email", "mcasadevall2@them.com",
            db_conn=self._db_connection)
        retrieved_contact = ndr_server.Contact.get_by_id(self._nsc, orig_contact.pg_id,
                                                         db_conn=self._db_connection)

        self.assertEqual(orig_contact, retrieved_contact)
        self.assertEqual(retrieved_contact.method, ndr_server.ContactMethods.EMAIL)
        self.assertEqual(retrieved_contact.value, "mcasadevall2@them.com")

    def test_expect_on_bad_read(self):
        '''Tests the expection in the storage procedure'''
        self.assertRaises(psycopg2.InternalError, ndr_server.Contact.get_by_id, self._nsc, 10000)

if __name__ == '__main__':
    unittest.main()
