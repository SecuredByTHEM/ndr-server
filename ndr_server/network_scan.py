# Copyright (C) 2017  Secured By THEM
# Original Author: Michael Casadevall <michaelc@them.com>
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

'''Handle network scan management and importation'''

import json

import ndr

class NetworkScan(object):
    '''Network Scans represent data in the database, and handling of scan differences'''

    def __init__(self, config):
        self.pg_id = None
        self.db_connection = None
        self.config = config
        self.nmap_scan = None

    @classmethod
    def create_from_message(cls, config, log_id, message, db_conn=None):
        '''Creates a NetworkScan object from the database'''
        storable_scan = ndr.NmapScan()
        storable_scan.from_message(message)

        net_scan = NetworkScan(config)
        net_scan.nmap_scan = storable_scan

        scan_json = json.dumps(storable_scan.to_dict())
        net_scan.pg_id = config.database.run_procedure_fetchone(
            "network_scan.import_scan", [log_id, scan_json],
            existing_db_conn=db_conn)[0]

        return net_scan

    def get_unknown_hosts_from_scan(self, db_conn=None):
        '''Determines what hosts are unknown'''

        unknown_host_ids = self.config.database.run_procedure_fetchone(
            "network_scan.return_hosts_not_in_baseline", [self.pg_id],
            existing_db_conn=db_conn)[0]

        # See if we have anything unknown in the scan
        if unknown_host_ids is None:
            return None

        # Poop, we need to retrieve the hosts from the database. While we have the hosts in our
        # scan, we don't have the pg_ids (an easy performance tweak is to get these as part as the
        # import)

        unknown_host_objs = []
        for host_id in unknown_host_ids:
            host_dict = self.config.database.run_procedure_fetchone(
                "network_scan.export_host", [host_id],
                existing_db_conn=db_conn)[0]

            # Convert the JSON to a host dict
            host_obj = ndr.NmapHost.from_dict(host_dict)
            unknown_host_objs.append(host_obj)

        return unknown_host_objs

    @staticmethod
    def add_host_to_baseline(config, host_pg_id, db_conn=None):
        '''Adds a host to the baseline so it's known from this point forward'''
        config.database.run_procedure(
            "network_scan.add_host_to_baseline", [host_pg_id],
            existing_db_conn=db_conn)
