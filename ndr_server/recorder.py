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

import datetime
import time
import ndr
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
        self.image_build_date = None
        self.image_type = None

    def __eq__(self, other):
        # Recorders equal each other if the pg_id matches each other
        # since its the same record in the database
        if self.pg_id is None:
            return False

        return self.pg_id == other.pg_id

    @classmethod
    def create(cls, config, site, human_name, hostname, db_conn=None):
        '''Creates the recorder within the database'''
        recorder = cls(config)
        recorder.human_name = human_name
        recorder.hostname = hostname
        recorder.site_id = site.pg_id

        recorder.enlisted_at = time.time()
        recorder.last_seen = recorder.enlisted_at

        recorder.pg_id = config.database.run_procedure_fetchone(
            "admin.insert_recorder", [site.pg_id, human_name, hostname],
            existing_db_conn=db_conn)[0]

        return recorder

    def from_dict(self, recorder_dict):
        '''Deserializes an recorder from a dictionary'''
        self.human_name = recorder_dict['human_name']
        self.hostname = recorder_dict['hostname']
        self.site_id = recorder_dict['site_id']
        self.pg_id = recorder_dict['id']
        self.image_build_date = recorder_dict['image_build_date']
        self.image_type = recorder_dict['image_type']

        return self

    def get_site(self, db_conn=None):
        '''Gets the site object for this recorder'''
        return ndr_server.Site.read_by_id(self.config, self.site_id, db_conn)

    def set_recorder_sw_revision(self, image_build_date, image_type, db_conn):
        '''Sets the recorder's software revision, and image type and updates the database
           with that information'''

        # Make sure we have an integer coming in
        image_build_date = int(image_build_date)
        self.config.database.run_procedure("admin.set_recorder_sw_revision",
                                           [self.pg_id, image_build_date, image_type],
                                           existing_db_conn=db_conn)
        self.image_build_date = image_build_date
        self.image_type = image_type

    def get_message_ids_recieved_in_time_period(self,
                                                message_type: ndr.IngestMessageTypes,
                                                start_period: datetime.datetime,
                                                end_period: datetime.datetime,
                                                db_conn):
        '''Retrieves message IDs recieved in for a given period'''
        cursor = self.config.database.run_procedure(
            "admin.get_recorder_message_ids_recieved_in_period",
            [self.pg_id,
             message_type.value,
             start_period,
             end_period],
            existing_db_conn=db_conn)

        message_ids = []
        for message_id in cursor.fetchall():
            message_ids.append(message_id)

        cursor.close()

        if len(message_ids) == 0:
            return None
        else:
            return message_ids

    @classmethod
    def read_by_id(cls, config, recorder_id, db_conn=None):
        '''Loads an recorder by ID number'''
        rec = cls(config)
        return rec.from_dict(config.database.run_procedure_fetchone(
            "ingest.select_recorder_by_id", [recorder_id], existing_db_conn=db_conn))

    @classmethod
    def read_by_hostname(cls, config, hostname, db_conn=None):
        '''Loads a recorder based of it's hostname in the database'''
        rec = cls(config)

        return rec.from_dict(config.database.run_procedure_fetchone(
            "ingest.select_recorder_by_hostname", [hostname], existing_db_conn=db_conn))

    @staticmethod
    def get_all_recorder_names(config, db_conn=None):
        '''Returns a list of all recorder names in the database'''

        return config.database.run_procedure(
            "admin.get_all_recorder_names", [], existing_db_conn=db_conn)
