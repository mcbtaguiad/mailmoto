FROM debian:trixie

LABEL Maintainer="Mark Taguiad <marktaguiad@marktaguiad.dev>"
LABEL Description="Docker MailMoTo"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
        postfix \
	dovecot-core \
        dovecot-imapd \
        dovecot-pop3d \
        dovecot-core \
	dovecot-lmtpd \
        mailutils \
	opendkim \
	opendkim-tools \
	opendmarc \
	mailutils \
	postgrey \
	rspamd \
	redis-server \
	spamassassin \ 
	spamd \
	netcat-traditional \
        gettext && \
    mkdir -p /etc/postfix/tls && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN rm -f /etc/ssl/private/ssl-cert-snakeoil.key \
           /etc/ssl/certs/ssl-cert-snakeoil.pem

# create virtual mail user
RUN groupadd -g 5000 vmail \
 && useradd -g vmail -u 5000 vmail -d /data/mail -m

RUN mkdir -p /data/mail \
 && chown -R vmail:vmail /data

RUN mkdir -p /var/spool/postfix/private \
 && chown postfix:postfix /var/spool/postfix/private \
 && chmod 770 /var/spool/postfix/private

# Postfix configs 
COPY postfix/main.cf.template /etc/postfix/main.cf.template
COPY postfix/main.cf.rspamd.template /etc/postfix/main.cf.rspamd.template
COPY postfix/master.cf /etc/postfix/master.cf

# Dovecot configs
COPY dovecot/dovecot.conf.template /etc/dovecot/dovecot.conf.template

# Opendkim
COPY opendkim/opendkim.conf.template /etc/opendkim.conf.template

# Opendmarc
COPY opendmarc/opendmarc.conf.template /etc/opendmarc.conf.template

# Rspamd
COPY rspamd/dkim_signing.conf.template /etc/rspamd/local.d/dkim_signing.conf.template
COPY rspamd/dmarc.conf.template /etc/rspamd/local.d/dmarc.conf.template
COPY rspamd/redis.conf /etc/rspamd/local.d/redis.conf
COPY rspamd/logging.inc /etc/rspamd/local.d/logging.inc

# Spamassassin
COPY spamassassin/local.cf /etc/spamassassin/local.cf
COPY spamassassin/spamd /etc/default/spamd

# Scripts
# Copy initialization scripts
COPY scripts/init_domain.sh /init_domain.sh

COPY scripts/entrypoint.sh /entrypoint.sh
COPY scripts/mailmoto /mailmoto

RUN chmod +x /entrypoint.sh
RUN chmod +x /mailmoto
RUN chmod +x /init_domain.sh

EXPOSE 25 587 465 143 993

ENTRYPOINT ["/entrypoint.sh"]
