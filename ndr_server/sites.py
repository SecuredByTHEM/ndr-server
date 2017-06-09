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

    def __init__(self, config, name):
        self.config = config
        self.org_id = None
        self.pg_id = None
        self.name = name

    def __eq__(self, other):
        return self.__dict__ == other.__dict__

    @classmethod
    def create(cls, config, organization, name, db_conn=None):
        '''Creates the organization within the database'''
        site = Site(config, name)
        site.org_id = organization.pg_id
        site.pg_id = config.database.run_procedure_fetchone(
            "admin.insert_site", [organization.pg_id, name],
            existing_db_conn=db_conn)[0]

        return site

    @classmethod
    def from_dict(cls, config, site_dict):
        '''Deserializes an organization from a dictionary'''
        site = Site(config, site_dict['name'])
        site.pg_id = site_dict['id']
        site.org_id = site_dict['org_id']
        return site

    def get_organization(self, db_conn=None):
        return ndr_server.Organization.read_by_id(self.config, self.org_id, db_conn=None)

    @staticmethod
    def read_by_id(config, site_id, db_conn=None):
        '''Loads an site by ID number'''
        return Site.from_dict(config, config.database.run_procedure_fetchone(
            "admin.select_site_by_id", [site_id], existing_db_conn=db_conn))

    @staticmethod
    def read_by_name(config, site_name, db_conn=None):
        '''Loads an site by name'''
        return Site.from_dict(config, config.database.run_procedure_fetchone(
            "admin.select_site_by_name", [site_name], existing_db_conn=db_conn))
