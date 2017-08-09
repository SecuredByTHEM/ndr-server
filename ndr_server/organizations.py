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

'''Repesentation of an Organization'''

import psycopg2
import psycopg2.extras

import ndr_server

class Organization(object):
    '''Organizations represent a paying customer. They can have multiple sites'''

    def __init__(self, config):
        self.config = config
        self.pg_id = None
        self.name = None

    def __eq__(self, other):
        '''We consider ourselves equal if pg_id matches. We never match when pg_id == None'''

        if self.pg_id is None:
            return False

        return self.pg_id == other.pg_id

    def from_dict(self, org_dict):
        '''Deserializes an organization from a dictionary'''
        self.name = org_dict['name']
        self.pg_id = org_dict['id']

        return self

    @classmethod
    def create(cls, config, name, db_conn=None):
        '''Creates the organization within the database'''
        org = Organization(config)
        org.name = name

        org.pg_id = config.database.run_procedure_fetchone(
            "admin.insert_organization", [name], existing_db_conn=db_conn)[0]

        return org

    @classmethod
    def read_by_id(cls, config, org_id, db_conn=None):
        '''Loads an organization by ID number'''
        org_dict = config.database.run_procedure_fetchone("admin.select_organization_by_id",
                                                          [org_id],
                                                          existing_db_conn=db_conn)
        org = cls(config)
        return org.from_dict(org_dict)

    @classmethod
    def read_by_name(cls, config, org_name, db_conn=None):
        '''Loads an organization by name'''
        org_dict = config.database.run_procedure_fetchone("admin.select_organization_by_name",
                                                          [org_name],
                                                          existing_db_conn=db_conn)

        org = cls(config)
        return org.from_dict(org_dict)

    def get_contacts(self, db_conn=None):
        '''Gets alert contacts for an organization'''
        cursor = self.config.database.run_procedure("admin.get_contacts_for_organization",
                                                    [self.pg_id], existing_db_conn=db_conn)

        contacts = []
        for record in cursor.fetchall():
            contacts.append(ndr_server.Contact.from_dict(self.config, record))

        return contacts
