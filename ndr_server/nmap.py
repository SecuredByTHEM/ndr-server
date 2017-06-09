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

# pylint: disable=too-many-arguments

'''Handles loading/storing NMAP scan objects in the database'''

import ndr


class NmapStorableScan(ndr.NmapScan):

    '''Represents a serializable to database Nmap Scan'''

    def __init__(self):
        self.pg_id = None
        ndr.NmapScan.__init__(self, config=None)

    def from_dict(self, scan_dict, host_class=None):
        '''Override the from_dict method to change the storable class'''
        ndr.NmapScan.from_dict(self, scan_dict, host_class=NmapStorableHost)


class NmapStorableHost(ndr.NmapHost):

    def __init__(self, state, reason, reason_ttl):
        ndr.NmapHost.__init__(self, state, reason, reason_ttl)

    @classmethod
    def from_dict(cls, host_dict, address_class=None, hostname_class=None, port_class=None, osmatch_class=None):
        return super(NmapStorableHost, cls).from_dict(host_dict,
                                                      address_class=None,
                                                      hostname_class=None,
                                                      port_class=None,
                                                      osmatch_class=None)

    def sanity_check(self):
        print("I'M SANE")
