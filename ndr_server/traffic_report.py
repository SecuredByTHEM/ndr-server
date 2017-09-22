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

'''Classes relating to management of data coming from SNORT'''

import ipaddress
import datetime

import ndr
import ndr_server

class TsharkTrafficReport(object):
    '''Traffic logs are generated by listening programs and summarizing all packets,
    then are consolated into a traffic report entry which is stored in the database'''

    def __init__(self, config):
        self.config = config
        self.recorder = None
        self.pg_id = None
        self.traffic_log = None

    @classmethod
    def create_from_message(cls, config, recorder, log_id, message, db_conn=None):
        '''Creates traffic log entries in the database from ingest message,

           Because there's no additional metadata assoicated with traffic logs,
           the message_id is the record of a given traffic log upload'''

        ingest_log = ndr.TrafficReportMessage()
        ingest_log.from_message(message)

        traffic_log = TsharkTrafficReport(config)
        traffic_log.recorder = recorder
        traffic_log.traffic_log = ingest_log
        traffic_log.pg_id = log_id

        for traffic_entry in ingest_log.traffic_entries:
            config.database.run_procedure(
                "traffic_report.create_traffic_report",
                [log_id,
                 traffic_entry.protocol.value,
                 traffic_entry.src_address.compressed,
                 traffic_entry.src_hostname,
                 traffic_entry.src_port,
                 traffic_entry.dst_address.compressed,
                 traffic_entry.dst_hostname,
                 traffic_entry.dst_port,
                 traffic_entry.rx_bytes,
                 traffic_entry.tx_bytes,
                 traffic_entry.start_timestamp,
                 traffic_entry.duration],
                existing_db_conn=db_conn)

        return traffic_log

class TsharkTrafficReportManager(object):
    '''Handles a summary of traffic report messages from the database'''

    def __init__(self, config, site, db_conn):
        self.config = config
        self.site = site
        self.organization = site.get_organization(db_conn)

    def retrieve_all_reports(self,
                             start_period: datetime.datetime,
                             end_period: datetime.datetime,
                             db_conn):

        '''Pulls the report based on time from the database'''

    def retrieve_geoip_breakdown(self,
                                 start_period: datetime.datetime,
                                 end_period: datetime.datetime,
                                 db_conn):
        '''Breaks down all traffic by destination country'''

        geoip_cursor = self.config.database.run_procedure(
            "traffic_report.report_geoip_breakdown_for_site",
            [self.site.pg_id,
             start_period,
             end_period],
            existing_db_conn=db_conn)

        import pprint
        pprint.pprint(geoip_cursor.fetchall())

    def retrieve_geoip_by_local_ip_breakdown(self,
                                             start_period: datetime.datetime,
                                             end_period: datetime.datetime,
                                             db_conn):
        '''Breaks down traffic by machine and destination'''

        local_ip_cursor = self.config.database.run_procedure(
            "traffic_report.report_traffic_breakdown_in_site_by_machine",
            [self.site.pg_id,
             start_period,
             end_period],
            existing_db_conn=db_conn)

        import pprint
        pprint.pprint(local_ip_cursor.fetchall())

    def retrieve_full_host_breakdown(self,
                                     start_period: datetime.datetime,
                                     end_period: datetime.datetime,
                                     db_conn):

        '''Breaks down remote traffic by machine and remote host destination'''

        traffic_breakdown = self.config.database.run_procedure(
            "traffic_report.report_traffic_breakdown_for_site",
            [self.site.pg_id,
             start_period,
             end_period],
            existing_db_conn=db_conn)

        import pprint
        pprint.pprint(traffic_breakdown.fetchall())

    def generate_report_emails(self, send=True, db_conn=None):
        '''Generates a report email breaking down traffic by country destination'''

