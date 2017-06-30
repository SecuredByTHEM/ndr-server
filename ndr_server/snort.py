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

import ndr

class TrafficLog(object):
    '''Traffic logs are generated by SNORT listening to all packets, then are consolated
    into a traffic report entry which is stored in the database'''

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

        ingest_log = ndr.SnortTrafficLog()
        ingest_log.from_message(message)

        traffic_log = TrafficLog(config)
        traffic_log.recorder = recorder
        traffic_log.traffic_log = ingest_log
        traffic_log.pg_id = log_id

        # Uploaded logs only have consolated traffic, and not the full traffic entries
        for traffic_entry in ingest_log.consolated_traffic:
            config.database.run_procedure(
                "snort.create_traffic_report",
                [log_id,
                 traffic_entry.src.compressed,
                 traffic_entry.srcport,
                 traffic_entry.dst.compressed,
                 traffic_entry.dstport,
                 traffic_entry.ethsrc,
                 traffic_entry.ethdst,
                 traffic_entry.proto.value,
                 traffic_entry.rxpackets,
                 traffic_entry.txpackets,
                 traffic_entry.firstseen],
                existing_db_conn=db_conn)

        return traffic_log
