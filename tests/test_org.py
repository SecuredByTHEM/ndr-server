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
SCHEMA = THIS_DIR + "/../sql/schema.sql"
GRANTS = THIS_DIR + "/../sql/grants.sql"
TEST_CONFIG = THIS_DIR + "/test_config.yml"


class TestOrganizations(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls._nsc = ndr_server.Config(logging.NullHandler(), TEST_CONFIG)
        cls._db_connection = cls._nsc.database.get_connection()

    @classmethod
    def tearDownClass(cls):
        cls._db_connection.rollback()
        cls._nsc.database.close()

    def test_create(self):
        '''Create an organization and make sure the procedural SQL don't go bang'''
        ndr_server.Organization.create(self._nsc, "Test 1", db_conn=self._db_connection)

    def test_read_by_id(self):
        '''We need to create a new ID so we know the pg_id from the insert and can read it back'''
        first_org = ndr_server.Organization.create(self._nsc, "Test 2", db_conn=self._db_connection)
        read_org = ndr_server.Organization.read_by_id(
            self._nsc, first_org.pg_id, db_conn=self._db_connection)

        self.assertEqual(first_org, read_org)

    def test_expect_on_bad_read(self):
        '''Tests database exception throwing'''
        self.assertRaises(psycopg2.InternalError,
                          ndr_server.Organization.read_by_id, self._nsc, 10000)

    def test_contact_retrieval(self):
        '''Retrieves all the contacts for a given organization'''

        # Create a new contact to all the goodness
        contact_org = ndr_server.Organization.create(
            self._nsc, "Contact Organization", db_conn=self._db_connection)

        # Now make some contacts and load them to this organization
        contact1 = ndr_server.Contact.create(
            self._nsc, contact_org, "email", "michaelc@them.com", db_conn=self._db_connection)
        contact2 = ndr_server.Contact.create(
            self._nsc, contact_org, "email", "davidm@them.com", db_conn=self._db_connection)

        # Everything should be committed, retrieve all the contacts, and make sure
        # we can find both contacts

        contact_list = contact_org.get_contacts(db_conn=self._db_connection)
        self.assertEqual(len(contact_list), 2)
        self.assertIn(contact1, contact_list)
        self.assertIn(contact2, contact_list)

if __name__ == '__main__':
    unittest.main()
