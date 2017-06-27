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

import unittest
import os
import logging
import tempfile
import shutil
import time

import ndr
import ndr_server

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
TEST_CONFIG = THIS_DIR + "/test_config.yml"
NMAP_ARP_SCAN = THIS_DIR + "/data/ingest/nmap_arp_scan.yml"
SYSLOG_SCAN = THIS_DIR + "/data/ingest/syslog_upload.yml"

EXPECTED_OUTPUT_UNKNOWN_HOST = THIS_DIR + "/data/expected_outputs/unknown_host"

class TestIngests(unittest.TestCase):
    '''Tests various ingest cases'''

    # Unlike most tests, we need to re-setup the environment per test run because the baseline
    # host behavior has a side-effect that can influence future runs

    def setUp(self):
        logging.getLogger().addHandler(logging.NullHandler())
        # Now load a global config object so the DB connection is open
        self._nsc = ndr_server.Config(logging.getLogger(), TEST_CONFIG)

        # We need to process test messages, so override the base directory for
        # this test
        self._db_connection = self._nsc.database.get_connection()

        # For this specific test, we need to create a few test objects
        self._test_org = ndr_server.Organization.create(
            self._nsc, "Network Scan Recorders Org", db_conn=self._db_connection)
        self._test_site = ndr_server.Site.create(
            self._nsc, self._test_org, "Network Scan Recorders Site", db_conn=self._db_connection)
        self._recorder = ndr_server.Recorder.create(
            self._nsc, self._test_site, "Test Recorder", "ndr_test_ingest",
            db_conn=self._db_connection)

        # We need a test file contact
        file_descriptor, self._test_contact = tempfile.mkstemp()
        os.close(file_descriptor) # Don't need to write anything to it

        ndr_server.Contact.create(
            self._nsc, self._test_org, "file", self._test_contact,
            db_conn=self._db_connection)

    def tearDown(self):
        self._db_connection.rollback()
        self._nsc.database.close()
        os.remove(self._test_contact)

    def load_network_scan(self, file_path):
        '''Loads a network scan'''
        with open(file_path, 'r') as yaml_msg:
            yaml_file = yaml_msg.read()

        message = ndr.IngestMessage()
        message.load_from_yaml(yaml_file)

        cursor = self._db_connection.cursor()
        cursor.callproc("ingest.create_upload_log", [self._recorder.pg_id,
                                                     message.message_type.value,
                                                     message.generated_at])
        log_id = cursor.fetchone()[0]

        net_scan = ndr_server.NetworkScan.create_from_message(self._nsc,
                                                              self._recorder,
                                                              log_id,
                                                              message,
                                                              db_conn=self._db_connection)
        return net_scan

    def test_unknown_hosts(self):
        '''Tests that we can detect unknown hosts'''
        net_scan = self.load_network_scan(NMAP_ARP_SCAN)
        host_objs = net_scan.get_unknown_hosts_from_scan(db_conn=self._db_connection)
        self.assertEqual(len(host_objs), 4)

    def test_adding_hosts_to_baseline(self):
        '''This tests the functionality of adding a host to a
           baseline properly removes it from unknown hosts'''

        # First, create a scan and import it
        net_scan = self.load_network_scan(NMAP_ARP_SCAN)
        unk_host_objs = net_scan.get_unknown_hosts_from_scan(db_conn=self._db_connection)
        self.assertEqual(len(unk_host_objs), 4)

        # Now, let's take the top object, add it to the baseline
        host_to_baseline = unk_host_objs.pop()
        self.assertIsNotNone(host_to_baseline.pg_id)

        ndr_server.NetworkScan.add_host_to_baseline(self._nsc,
                                                    host_to_baseline.pg_id,
                                                    db_conn=self._db_connection)

        # Now import the scan again, and make sure the host isn't there
        net_scan = self.load_network_scan(NMAP_ARP_SCAN)
        second_scan = net_scan.get_unknown_hosts_from_scan(db_conn=self._db_connection)

        self.assertEqual(len(second_scan), 3)
        for host in second_scan:
            self.assertNotEqual(host, host_to_baseline)

        # Now add everything and make sure we don't get any results
        for host in second_scan:
            ndr_server.NetworkScan.add_host_to_baseline(self._nsc,
                                                        host.pg_id,
                                                        db_conn=self._db_connection)

        final_scan = self.load_network_scan(NMAP_ARP_SCAN)
        self.assertIsNone(net_scan.get_unknown_hosts_from_scan(db_conn=self._db_connection))

    def test_message_notifications(self):
        '''Tests the behavior of test notifications for scan results'''

        # We've done this before
        net_scan = self.load_network_scan(NMAP_ARP_SCAN)
        unk_host_objs = net_scan.get_unknown_hosts_from_scan(db_conn=self._db_connection)
        self.assertEqual(len(unk_host_objs), 4)

        fake_timestamp = 1498548342

        msg = ndr_server.UnknownMachineTemplate(
            self._test_org, self._test_site, self._recorder, unk_host_objs, fake_timestamp
        ).prepped_message()

        # Because the order is not promised by the database, we need to make sure that the
        # essential lines are there.

        self.assertIn("MAC Address: 40:16:7e:6c:04:92", msg)
        self.assertIn("Manufacturer: Asustek Computer", msg)
        self.assertIn("Detection Method: arp-response", msg)

    def test_do_alerting(self):
        '''Tests the alerting functionality of the scan results'''

        # Oh look, we need to do this AGAIN
        net_scan = self.load_network_scan(NMAP_ARP_SCAN)
        net_scan.do_alerting(db_conn=self._db_connection)

        # Now read in the alert test file and see what we see
        with open(self._test_contact, 'r') as f:
            alert_contents = f.read()

        # Like before, let's make sure we have the essentials there
        self.assertIn("MAC Address: 40:16:7e:6c:04:92", alert_contents)
        self.assertIn("Manufacturer: Asustek Computer", alert_contents)
        self.assertIn("Detection Method: arp-response", alert_contents)


if __name__ == '__main__':
    unittest.main()
