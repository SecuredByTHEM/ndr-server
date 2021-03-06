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

import socket

import yaml
import ndr_server

class Config:
    '''Holds configuration information for ingest'''

    def __init__(self, logger, yaml_file):
        with open(yaml_file, 'r') as f:
            config_dict = yaml.safe_load(f)

        self.base_directory = config_dict['base_directory']

        # Ident settings
        if "hostname" in config_dict:
            self.hostname = config_dict['hostname']
        else:
            self.hostname = socket.gethostname()

        # S/MIME settings
        self.smime_enabled = config_dict['smime']['enabled']
        self.smime_ca = config_dict['smime']['cafile']
        self.smime_mail_certfile = config_dict['smime']['mail_certfile']
        self.smime_mail_private_key = config_dict['smime']['mail_keyfile']

        # DB settings
        self.db_hostname = config_dict['postgresql']['host']
        self.db_username = config_dict['postgresql']['user']
        self.db_password = config_dict['postgresql']['password']
        self.db_dbname = config_dict['postgresql']['dbname']

        # Mail server settings
        self.smtp_disabled = False
        if "disable" in config_dict['smtp']:
            self.smtp_disabled = config_dict['smtp']['disable']

        self.mail_from = config_dict['smtp']['mail_from']
        self.smtp_host = config_dict['smtp']['smtp_host']
        self.smtp_username = config_dict['smtp'].get('smtp_username', None)
        self.smtp_password = config_dict['smtp'].get('smtp_password', None)

        self.uucp_sys_config = '/etc/uucp/sys'

        self.logger = logger

        self.geoip_db = config_dict.get('geoip_database', '/etc/ndr/geoip.mmdb')

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
        return "host='%s' dbname='%s' user='%s' password='%s'" % (self.db_hostname, self.db_dbname, self.db_username, self.db_password)

    def update_uucp_sys_file(self, db_conn=None):
        '''Updates the UUCP sys configuration file

        This is a relatively horrid hack right now to allow us to use Taylor UUCP. At some
        point in the near future, I need to modify UUCP to be able to read its configuration
        from a database'''

        uucp_config_file = ''

        # This is really horrid
        recorders_list = ndr_server.Recorder.get_all_recorder_names(self, db_conn=db_conn)

        # The top of the file is a hardcoded for protocols we accept and use in general
        # CHECKME: see if this is really necessary
        uucp_config_file += "protocol gvG\n"
        uucp_config_file += "protocol-parameter G packet-size 1024\n"
        uucp_config_file += "protocol-parameter G short-packets\n"
        uucp_config_file += "remote-receive " + self.incoming_directory + " " + self.enrollment_directory + "\n\n"

        for recorder in recorders_list:
            uucp_config_file += "system " + recorder[0] + "\n"
            uucp_config_file += "protocol t\n"

        with open(self.uucp_sys_config, 'w') as f:
            f.write(uucp_config_file)
