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

'''Repesentation of an recorder'''

import time
import ndr_server


class Recorder(object):

    '''Recorders are a system running the NDR package, and represent a source of data'''

    def __init__(self, config):
        self.config = config
        self.pg_id = None
        self.site_id = None
        self.human_name = None
        self.hostname = None
        self.enlisted_at = None
        self.last_seen = None

    def __eq__(self, other):
        # Recorders equal each other if the pg_id matches each other
        # since its the same record in the database
        return self.pg_id == other.pg_id

    @classmethod
    def create(cls, config, site, human_name, hostname, db_conn=None):
        '''Creates the recorder within the database'''
        recorder = Recorder(config)
        recorder.human_name = human_name
        recorder.hostname = hostname
        recorder.site_id = site.pg_id

        recorder.enlisted_at = time.time()
        recorder.last_seen = recorder.enlisted_at

        recorder.pg_id = config.database.run_procedure_fetchone(
            "admin.insert_recorder", [site.pg_id, human_name, hostname],
            existing_db_conn=db_conn)[0]

        return recorder

    @classmethod
    def from_dict(cls, config, recorder_dict):
        '''Deserializes an recorder from a dictionary'''
        recorder = Recorder(config)
        recorder.human_name = recorder_dict['human_name']
        recorder.hostname = recorder_dict['hostname']
        recorder.site_id = recorder_dict['site_id']
        recorder.pg_id = recorder_dict['id']

        return recorder

    def get_site(self, db_conn=None):
        '''Gets the site object for this recorder'''
        return ndr_server.Site.read_by_id(self.config, self.site_id, db_conn)

    @staticmethod
    def read_by_id(config, recorder_id, db_conn=None):
        '''Loads an recorder by ID number'''
        return Recorder.from_dict(config, config.database.run_procedure_fetchone(
            "ingest.select_recorder_by_id", [recorder_id], existing_db_conn=db_conn))

    @staticmethod
    def read_by_hostname(config, hostname, db_conn=None):
        '''Loads a recorder based of it's hostname in the database'''

        return Recorder.from_dict(config, config.database.run_procedure_fetchone(
            "ingest.select_recorder_by_hostname", [hostname], existing_db_conn=db_conn))

    @staticmethod
    def get_all_recorder_names(config, db_conn=None):
        '''Returns a list of all recorder names in the database'''

        return config.database.run_procedure(
            "admin.get_all_recorder_names", [], existing_db_conn=db_conn)
