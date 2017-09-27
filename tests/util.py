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

'''Utility functions helpful across multiple test modules'''

import tempfile
import shutil

import ndr_server

def ingest_test_file(self, filename):
    '''Simply feeds in the response for an ingest test'''
    file_contents = ""
    with open(filename, 'r') as scanfile:
        file_contents = scanfile.read()

    ingest_daemon = ndr_server.IngestServer(self._nsc)

    ingest_daemon.process_ingest_message(self._db_connection, self._recorder, file_contents)

