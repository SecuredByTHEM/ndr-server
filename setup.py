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

from setuptools import setup, find_packages

setup(
    name="ndr-server",
    version="0.1",
    packages=find_packages(exclude=("tests",)),
    install_requires=[
        'cryptography',
        'pyyaml',
        'psycopg2 >= 2.7',
        'pytz',
        'geoip2',
        'terminaltables'
    ],
    entry_points={
        'console_scripts': [
            'ndr-ingest-server = ndr_server.tools.server:main',
            'ndr-process-enlistments = ndr_server.tools.process_enlistment:main',
            'ndr-reboot-recorder = ndr_server.tools.reboot_recorder:main',
            'ndr-run-daily = ndr_server.tools.run_daily:main'
        ]
    },
    test_suite="tests"
)
