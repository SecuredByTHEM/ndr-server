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

'''NDR Server Configuration'''

import yaml
import ndr_server

class Config:
    '''Holds configuration information for ingest'''

    def __init__(self, logger, yaml_file):
        with open(yaml_file, 'r') as f:
            config_dict = yaml.safe_load(f)

        self.base_directory = config_dict['base_directory']

        # S/MIME settings
        self.smime_ca = config_dict['smime']['cafile']
        self.smime_mail_certfile = config_dict['smime']['mail_certfile']
        self.smime_mail_private_key = config_dict['smime']['mail_keyfile']

        # DB settings
        self.db_hostname = config_dict['postgresql']['host']
        self.db_username = config_dict['postgresql']['user']
        self.db_dbname = config_dict['postgresql']['dbname']

        # Mail server settings
        self.smtp_disabled = False
        if "disable" in config_dict['smtp']:
            self.smtp_disabled = config_dict['smtp']['disable']

        self.mail_from = config_dict['smtp']['mail_from']
        self.smtp_host = config_dict['smtp']['smtp_host']
        self.smtp_username = config_dict['smtp']['smtp_username']
        self.smtp_password = config_dict['smtp']['smtp_password']

        # Used for testing, postgres superuser
        self.postgres_superuser = None
        if "postgres_superuser" in config_dict:
            self.postgres_superuser = config_dict['postgres_superuser']['user']

        self.logger = logger

        # Initialize the database connection with this config so it's obtainable down the pipe
        self.database = ndr_server.Database(self)

    @property
    def accepted_directory(self):
        '''Place where accepted messages are stored after processing'''
        return self.base_directory + '/accepted'

    @property
    def incoming_directory(self):
        '''Where new messages are stored on the filesystem before ingesting'''
        return self.base_directory + '/incoming'

    @property
    def reject_directory(self):
        '''Where the rejects go'''
        return self.base_directory + '/rejected'

    @property
    def error_directory(self):
        '''Where error messages are stored'''
        return self.base_directory + '/error'

    @property
    def enrollment_directory(self):
        '''Where error messages are stored'''
        return self.base_directory + '/enrollment'

    def get_pg_connect_string(self):
        '''Returns the connection string required for pyschopg2'''
        return "host='%s' dbname='%s' user='%s'" % (self.db_hostname, self.db_dbname, self.db_username)

    def get_pg_superuser_connect_string(self):
        '''Returns a connection string for the superuser for creating/dropping the database as a test user'''
        return "host='%s' user='%s'" % (self.db_hostname, self.postgres_superuser)

#"host='localhost' dbname='ndr' user='ndr_ingest'"
