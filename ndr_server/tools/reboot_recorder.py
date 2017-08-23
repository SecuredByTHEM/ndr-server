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

'''Sends a message to the recorder to tell it to reboot at the next checkin to process
updates and reset state information'''

import argparse
import logging
import psycopg2

import ndr
import ndr_server

def main():
    # Do our basic setup work
    logging.basicConfig(format='%(asctime)s %(levelname)s %(message)s')
    logger = logging.getLogger(name=__name__)
    logger.setLevel(logging.DEBUG)

    # We need both configs
    ncc = ndr.Config("/etc/ndr/config.yml") # NDR Client Config
    nsc = ndr_server.Config(logger, "/etc/ndr/ndr_server.yml")
    db_connection = nsc.database.get_connection()

    parser = argparse.ArgumentParser(
        description="Requests that a recorder restart to install OTAs updates")
    parser.add_argument('recorders', nargs='+',
                        help='recorders to reboot')
    args = parser.parse_args()
    for recorder in args.recorders:
        # Make sure the recorder exists
        try:
            # We'll try to initialize a Recorder object. We don't need it but it confirms
            # that the recorder exists in the datbase

            ndr_server.Recorder.read_by_hostname(nsc, recorder, db_conn=db_connection)
            msg = ndr.IngestMessage(config=ncc, message_type=ndr.IngestMessageTypes.REBOOT_REQUEST)

            msg.destination = recorder
            msg.upload_method = 'uux'
            msg.sign_report()
            msg.load_into_queue()
            logger.info("Queued recorder %s to reboot", recorder)

        except psycopg2.DatabaseError:
            logger.error("recorder %s does not exist", recorder)

    db_connection.close()

if __name__ == '__main__':
    main()
