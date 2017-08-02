#!/usr/bin/python3
# Copyright (C) 2017  Secured By THEM
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

'''Ingest daemon for NDR'''
import logging
import ndr_server

def main():
    logging.basicConfig(format='%(asctime)s %(levelname)s %(message)s')
    logger = logging.getLogger(name=__name__)
    logger.setLevel(logging.DEBUG)

    ndr_server_config = ndr_server.Config(
        logger, "/etc/ndr/ndr_server.yml")
    ingest_daemon = ndr_server.IngestServer(ndr_server_config)
    ingest_daemon.start_server()

if __name__ == "__main__":
    main()
