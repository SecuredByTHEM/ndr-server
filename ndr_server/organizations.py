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

    def __init__(self, config, name):
        self.config = config
        self.pg_id = None
        self.name = name

    def __eq__(self, other):
        return self.__dict__ == other.__dict__

    @classmethod
    def from_dict(cls, config, org_dict):
        '''Deserializes an organization from a dictionary'''
        org = Organization(config, org_dict['name'])
        org.pg_id = org_dict['id']

        return org

    @classmethod
    def create(cls, config, name, db_conn=None):
        '''Creates the organization within the database'''
        org = Organization(config, name)

        org.pg_id = config.database.run_procedure_fetchone(
            "admin.insert_organization", [name], existing_db_conn=db_conn)[0]

        return org

    @staticmethod
    def read_by_id(config, org_id, db_conn=None):
        '''Loads an organization by ID number'''
        return Organization.from_dict(config, config.database.run_procedure_fetchone(
            "admin.select_organization_by_id", [org_id], existing_db_conn=db_conn))

    @staticmethod
    def read_by_name(config, org_name, db_conn=None):
        '''Loads an organization by name'''
        return Organization.from_dict(config, config.database.run_procedure_fetchone(
            "admin.select_organization_by_name", [org_name], existing_db_conn=db_conn))

    def get_contacts(self, db_conn=None):
        '''Gets alert contacts for an organization'''
        cursor = self.config.database.run_procedure("admin.get_contacts_for_organization",
                                                    [self.pg_id], existing_db_conn=db_conn)

        contacts = []
        for record in cursor.fetchall():
            contacts.append(ndr_server.Contact.from_dict(self.config, record))

        return contacts
