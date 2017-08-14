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

import ndr_server

class Site(object):
    '''Sites represent a physical location. Recorders exist within sites'''

    def __init__(self, config):
        self.config = config
        self.org_id = None
        self.pg_id = None
        self.name = None

    def __eq__(self, other):
        '''We consider ourselves equal if pg_id matches. We never match when pg_id == None'''

        if self.pg_id is None:
            return False

        return self.pg_id == other.pg_id

    @classmethod
    def create(cls, config, organization, name, db_conn=None):
        '''Creates the organization within the database'''
        site = cls(config)
        site.name = name
        site.org_id = organization.pg_id
        site.pg_id = config.database.run_procedure_fetchone(
            "admin.insert_site", [organization.pg_id, name],
            existing_db_conn=db_conn)[0]

        return site

    def from_dict(self, site_dict):
        '''Deserializes an organization from a dictionary'''
        self.name = site_dict['name']
        self.pg_id = site_dict['id']
        self.org_id = site_dict['org_id']
        return self

    def get_organization(self, db_conn=None):
        '''Returns parent organization'''
        return ndr_server.Organization.read_by_id(self.config, self.org_id, db_conn=db_conn)

    @classmethod
    def read_by_id(cls, config, site_id, db_conn=None):
        '''Loads an site by ID number'''

        site = cls(config)
        return site.from_dict(config.database.run_procedure_fetchone(
            "admin.select_site_by_id", [site_id], existing_db_conn=db_conn))

    @classmethod
    def read_by_name(cls, config, site_name, db_conn=None):
        '''Loads an site by name'''

        site = cls(config)
        return site.from_dict(config.database.run_procedure_fetchone(
            "admin.select_site_by_name", [site_name], existing_db_conn=db_conn))
