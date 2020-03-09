#!/bin/sh

curl  https://get.acme.sh | sh
mkdir -p /var/vmail/cert/
if [ `env | grep DP_Id | wc -l` == 1 ]
then
    ~/.acme.sh/acme.sh --issue --dns dns_dp -d $HOSTNAME --cert-file /var/vmail/cert/$HOSTNAME.crt  --key-file /var/vmail/cert/$HOSTNAME.key --ca-file /var/vmail/cert/$HOSTNAME.ca.cer --fullchain-file /var/vmail/cert/$HOSTNAME.pem --dnssleep 60
else
    ~/.acme.sh/acme.sh --issue --dns dns_ali -d $HOSTNAME --cert-file /var/vmail/cert/$HOSTNAME.crt  --key-file /var/vmail/cert/$HOSTNAME.key --ca-file /var/vmail/cert/$HOSTNAME.ca.cer --fullchain-file /var/vmail/cert/$HOSTNAME.pem --dnssleep 60

#Config Nginx Certificate
mv /etc/ssl/certs/iRedMail.crt{,.bak}
mv /etc/ssl/private/iRedMail.key{,.bak}
ln -s /var/vmail/cert/$HOSTNAME.pem /etc/ssl/certs/iRedMail.crt
ln -s /var/vmail/cert/$HOSTNAME.key /etc/ssl/private/iRedMail.key
ps -ef | grep 'nginx: master' | grep -v grep | awk '{print $2}' | xargs kill -9

#Config SMTP Certificate
postconf -e smtpd_tls_cert_file='/var/vmail/cert/$HOSTNAME.crt'
postconf -e smtpd_tls_key_file='/var/vmail/cert/$HOSTNAME.key'
postconf -e smtpd_tls_CAfile='/var/vmail/cert/$HOSTNAME.pem'
postfix reload

#Config Deovecot Certificate
sed -i "s#\#ssl_ca = </path/to/ca#ssl_ca = </var/vmail/cert/$HOSTNAME.pem#g" /etc/dovecot/dovecot.conf
dovecot reload

#Config MySQL Certificate
sed -i "s#\#ssl-ca =#ssl_ca = /var/vmail/cert/$HOSTNAME.pem#g" /etc/my.cnf
ps -ef | grep mysql | grep -v grep | awk '{print $2}' | xargs kill -9
