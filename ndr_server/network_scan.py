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
import collections

import ndr
import ndr_server

DISCOVERY_SCAN_TYPES = [
    ndr.NmapScanTypes.ARP_DISCOVERY,
    ndr.NmapScanTypes.ND_DISCOVERY,
    ndr.NmapScanTypes.IPV6_LINK_LOCAL_DISCOVERY
]

NetworkScanAlertStatus = collections.namedtuple('NetworkScanAlertStatus',
                                                'site_id host_id \
                                                 generated_at last_seen alerted_at')

class NetworkScanAlertTracker(object):
    '''Network Alert Tracker is used to register alerts with the backend,
       supress duplicates, and batch alerts'''

    def __init__(self, config):
        self.config = config

    def register_unknown_hosts(self, site, hosts, db_conn):
        '''Takes a list of NmapHosts which are unknown and registers them that they need to alert'''

        for host in hosts:
            if host.pg_id is None:
                raise ValueError("Hosts must have a pg_id (aka, loaded from database), \
                                  not directly loaded from message!")

            self.config.database.run_procedure(
                "alert.register_or_update_network_scan_alert",
                [site.pg_id, host.pg_id],
                existing_db_conn=db_conn)

    def get_alert_status_for_site(self, site, db_conn):
        '''Returns a report of alerts in the system'''

        alert_rows = self.config.database.run_procedure_fetchall(
            "alert.get_network_scan_alert_status_for_site",
            [site.pg_id],
            existing_db_conn=db_conn
        )

        alerts = []
        for alert in alert_rows:
            alerts.append(
                NetworkScanAlertStatus(
                    site_id=alert['site_id'],
                    host_id=alert['host_id'],
                    generated_at=alert['generated_at'],
                    last_seen=alert['last_seen'],
                    alerted_at=alert['alerted_at']
                )
            )

        return alerts

    def generate_alert_emails_for_site(self, site, db_conn):
        '''Generate alert emails as necessary'''

        # Retrieve our own records.
        alert_status = self.get_alert_status_for_site(site, db_conn)

        alerts_to_send = []

        # Determine which alerts to send
        for alert in alert_status:
            # If we've never alerted for this machine, add it to the send list
            if alert.alerted_at is None:
                alerts_to_send.append(alert)


class NetworkScan(object):
    '''Network Scans represent data in the database, and handling of scan differences'''

    def __init__(self, config):
        self.pg_id = None
        self.config = config
        self.recorder = None
        self.nmap_scan = None
        self.message = None

    @classmethod
    def create_from_message(cls, config, recorder, log_id, message, db_conn=None):
        '''Creates a NetworkScan object from the database'''
        storable_scan = ndr.NmapScan()
        storable_scan.from_message(message)

        net_scan = NetworkScan(config)
        net_scan.recorder = recorder
        net_scan.nmap_scan = storable_scan
        net_scan.message = message

        scan_json = json.dumps(storable_scan.to_dict())
        net_scan.pg_id = config.database.run_procedure_fetchone(
            "network_scan.import_scan", [log_id, scan_json],
            existing_db_conn=db_conn)[0]

        return net_scan

    def do_alert_processing(self, db_conn=None):
        '''Raises any alerts based on the type of scan it is'''

        # For the time being, we only do alerting for discovery scans.
        nsat = ndr_server.NetworkScanAlertTracker(self.config)
        site = self.recorder.get_site(db_conn)

        if self.nmap_scan.scan_type in DISCOVERY_SCAN_TYPES:
            unknown_hosts = self.get_unknown_hosts_from_scan(db_conn)
            if unknown_hosts is None:
                # We know evertyhing
                return

            # Register the unknown hosts with the alert tracker
            nsat.register_unknown_hosts(site, unknown_hosts, db_conn)

            # Get the necessary bits of info required to send alerts
            #site = self.recorder.get_site(db_conn=db_conn)
            #organization = site.get_organization(db_conn=db_conn)
            #alert_contacts = organization.get_contacts(db_conn=db_conn)

            # Generate the alert message
            #msg = ndr_server.UnknownMachineTemplate(
            #    organization, site, self.recorder, unknown_hosts, self.message.generated_at
            #)

            #alert_contacts = organization.get_contacts(db_conn=db_conn)

            #for contact in alert_contacts:
            #    contact.send_message(
            #        msg.subject(), msg.prepped_message()
            #    )

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
