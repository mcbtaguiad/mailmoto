#!/bin/bash

# Default values
MAIL_DOMAIN=${MAIL_DOMAIN:-example.com}
MAIL_HOSTNAME=${MAIL_HOSTNAME:-mail.example.com}

export MAIL_DOMAIN
export MAIL_HOSTNAME

# Generate postfix config
envsubst < /etc/postfix/main.cf.template > /etc/postfix/main.cf
sed -i 's|^mailbox_command =.*|mailbox_command = /usr/lib/dovecot/deliver -d \${recipient}|' /etc/postfix/main.cf
# Generate dovecot config
envsubst < /etc/dovecot/dovecot.conf.template > /etc/dovecot/dovecot.conf

# Generate opendkim config
envsubst < /etc/opendkim.conf.template > /etc/opendkim.conf

# Run domain init if first start
if [ ! -f /data/.initialized ]; then
  /init_domain.sh
  touch /data/.initialized
fi

# postfix upgrade-configuration

# dovecot -F  &
# postfix start-fg  

# cat /etc/postfix/main.cf

# Start services
service opendkim start
service dovecot start
service postfix start

touch /var/log/mail.log

tail -f /var/log/mail.log

exec "$@"
