#!/bin/sh
sed -i "s/DOMAIN/${DOMAIN}/g" /etc/dovecot/dovecot.conf

# Update password
. /opt/iredmail/.cv
sed -i "s/TEMP_VMAIL_DB_BIND_PASSWD/$VMAIL_DB_BIND_PASSWD/" /etc/dovecot/dovecot-mysql.conf
sed -i "s/TEMP_VMAIL_DB_ADMIN_PASSWD/$VMAIL_DB_ADMIN_PASSWD/" /etc/dovecot/dovecot-share-folder.conf /etc/dovecot/dovecot-used-quota.conf /etc/dovecot/dovecot-last-login.conf

echo "*** Starting dovecot.."
logger DEBUG Starting dovecot
touch /var/tmp/dovecot.run
exec /usr/sbin/dovecot -F -c /etc/dovecot/dovecot.conf
