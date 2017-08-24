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

'''Manages file revisions of data on the recorders'''

import collections

import ndr

RecorderFileRecord = collections.namedtuple(
    'RecorderFileRecord', 'pg_id file_type expected_sha256 recorder_sha256 blob_id'
)

class RecorderFileManager(object):
    '''Handles records of recorder files'''
    def __init__(self, config):
        self.config = config
        self.recorder = None
        self.file_info = {}

    @classmethod
    def get_for_recorder(cls, config, recorder, db_conn):
        '''Gets a file manager for a recorder'''

        rfm = cls(config)
        rfm.recorder = recorder
        rfm.refresh(db_conn)
        return rfm

    def refresh(self, db_conn):
        '''Refreshes the file contents info from the database'''
        cursor = self.config.database.run_procedure("configs.get_recorder_files",
                                                    [self.recorder.pg_id],
                                                    db_conn)

        self.file_info = {}
        for record in cursor.fetchall():
            file_type = ndr.NdrConfigurationFiles(record['file_type'])
            file_record = RecorderFileRecord(
                pg_id=record['id'],
                file_type=file_type,
                expected_sha256=record['expected_sha256'],
                recorder_sha256=record['recorder_sha256'],
                blob_id=record['file_blob_id']
            )

            self.file_info[file_type] = file_record

    def add_or_update_file(self, file_type: ndr.NdrConfigurationFiles, file: bytes, db_conn):
        '''Adds or updates a file on the recorder'''
        self.config.database.run_procedure("configs.add_or_update_recorder_files",
                                           [self.recorder.pg_id, file_type.value, file],
                                           db_conn)
        self.refresh(db_conn) # to get the calculated SHA256 sums. This could be optimized ...

    def get_file(self, file_type, db_conn):
        '''Retrieves a file from the database'''
        pass
