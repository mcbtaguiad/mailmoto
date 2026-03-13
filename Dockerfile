FROM ubuntu:24.04

LABEL Maintainer="Mark Taguiad <marktaguiad@marktaguiad.dev>"
LABEL Description="Docker MailMoTo"

RUN apt-get update && \
    apt-get install -y \
        postfix \
        dovecot-imapd \
        dovecot-pop3d \
        dovecot-core \
        mailutils \
	rspamd \
	opendkim \
	opendkim-tools \
	mailutils \
        gettext && \
    mkdir -p /etc/postfix/tls && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set Dovecot logging to stdout and enable auth debug
RUN sed -i 's|^#log_path =.*|log_path = /dev/stdout|' /etc/dovecot/conf.d/10-logging.conf \
 && sed -i 's|^#info_log_path =.*|info_log_path = /dev/stdout|' /etc/dovecot/conf.d/10-logging.conf \
 && sed -i 's|^#auth_verbose =.*|auth_verbose = yes|' /etc/dovecot/conf.d/10-logging.conf \
 && sed -i 's|^#auth_debug =.*|auth_debug = yes|' /etc/dovecot/conf.d/10-logging.conf \
 && sed -i 's|^#auth_debug_passwords =.*|auth_debug_passwords = no|' /etc/dovecot/conf.d/10-logging.conf

# create virtual mail user
RUN groupadd -g 5000 vmail \
 && useradd -g vmail -u 5000 vmail -d /data/mail -m

RUN mkdir -p /data/mail \
 && chown -R vmail:vmail /data

# Postfix configs 
COPY postfix/main.cf.template /etc/postfix/main.cf.template
COPY postfix/master.cf /etc/postfix/master.cf

# Dovecot configs
COPY dovecot/dovecot.conf.template /etc/dovecot/dovecot.conf.template

# Scripts
# Copy initialization scripts
COPY scripts/init_domain.sh /init_domain.sh

COPY scripts/entrypoint.sh /entrypoint.sh
COPY scripts/mailmoto /mailmoto



RUN chmod +x /entrypoint.sh

EXPOSE 25 587 465 143 993

ENTRYPOINT ["/entrypoint.sh"]
