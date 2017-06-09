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

'''Representation and encapulsation of an alert contact'''

from enum import Enum

import smtplib
import tempfile
import os
import subprocess
from email.mime.text import MIMEText

class Contact(object):
    '''Contacts represent people we reach when shit hits the fan. Contacts are currently attached
       on an organization level so a person can be presented in multiple organizations by each orgs
       security officer. We might add additional abilities to localize contacts to a site level in
       future'''

    def __init__(self, config, method, value):
        self.config = config
        self.method = ContactMethods(method)
        self.value = value
        self.pg_id = None
        self.org_id = None

    def __eq__(self, other):
        return self.__dict__ == other.__dict__

    @classmethod
    def create(cls, config, organization, method, value, db_conn=None):
        '''Creates a new contact attached to an organization'''

        contact = Contact(config, method, value)
        contact.org_id = organization.pg_id

        contact.pg_id = config.database.run_procedure_fetchone(
            "admin.insert_contact", [organization.pg_id, method, value],
            existing_db_conn=db_conn)[0]

        return contact

    @classmethod
    def from_dict(cls, config, contact_dict):
        '''Deserializes an organization from a dictionary'''
        contact = Contact(config, contact_dict['method'], contact_dict['value'])
        contact.pg_id = contact_dict['id']
        contact.org_id = contact_dict['org_id']

        return contact

    @classmethod
    def get_by_id(cls, config, contact_id, db_conn=None):
        return Contact.from_dict(config, config.database.run_procedure_fetchone(
            "admin.select_contact_by_id", [contact_id], existing_db_conn=db_conn))

    def send_message(self, subject, message):
        '''Sends an alert message'''

        if self.config.smtp_disabled:
            self.config.logger.info("Would send message to %s", self.value)
            # Mail is disabled, just return
            return

        # Sign the message
        try:
            msg_fd, unsigned_msg_file = tempfile.mkstemp()
            os.write(msg_fd, bytes(message, 'utf-8'))
            os.close(msg_fd)
            msg_fd = 0

            openssl_cmd = ["openssl", "smime", "-sign", "-md", "sha256", "-in", unsigned_msg_file,
                           "-signer", self.config.smime_mail_certfile, "-inkey",
                           self.config.smime_mail_private_key, "-text",
                           "-to", self.value,
                           "-from", self.config.mail_from,
                           "-subject", subject]

            openssl_proc = subprocess.run(
                args=openssl_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)

            if openssl_proc.returncode != 0:
                raise ValueError(str(openssl_proc.stderr, 'utf-8'))

            signed_message = str(openssl_proc.stdout, 'utf-8')

        finally:
            if msg_fd != 0:
                os.close(msg_fd)
            os.remove(unsigned_msg_file)

        # And send it on its way
        self.config.logger.info("Sending message to %s", self.value)
        smtp_server = smtplib.SMTP(self.config.smtp_host)
        smtp_server.starttls()
        smtp_server.login(self.config.smtp_username, self.config.smtp_password)
        smtp_server.sendmail(self.config.mail_from, self.value, signed_message)
        smtp_server.quit()

class ContactMethods(Enum):
    '''Known methods to contact folks'''
    EMAIL = "email"
