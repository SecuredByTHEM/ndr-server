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

'''Does daily processing of NDR server tasks'''

import argparse
import logging

from datetime import datetime, timedelta
import ndr_server

def main():
    '''Main function for handling daily processing tasks'''

    # Do our basic setup work
    logging.basicConfig(format='%(asctime)s %(levelname)s %(message)s')
    logger = logging.getLogger(name=__name__)
    logger.setLevel(logging.DEBUG)

    # We need both configs
    parser = argparse.ArgumentParser(
        description="Run daily processing tasks for NDR")
    parser.add_argument('-s', '--server-config',
                        default='/etc/ndr/ndr_server.yml',
                        help='NDR Server Configuration File')
    args = parser.parse_args()

    nsc = ndr_server.Config(logger, args.server_config)

    db_conn = nsc.database.get_connection()

    nsc.logger.info("Generating GeoIP statistics email")

    # Retrieve all sites
    sites = ndr_server.Site.retrieve_all(nsc, db_conn)

    for site in sites:
        nsc.logger.info("Processing site %s (%d)", site.name, site.pg_id)

        # TShark Reports
        report_manager = ndr_server.TsharkTrafficReportManager(nsc,
                                                               site,
                                                               db_conn)

        report_manager.generate_report_emails(datetime.now() - timedelta(days=1),
                                              datetime.now(),
                                              db_conn=db_conn,
                                              send=True,
                                              csv_output=True)

    db_conn.commit()

if __name__ == '__main__':
    main()
