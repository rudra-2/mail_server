FROM ubuntu:22.04

LABEL maintainer="Reloop Mail Server"

ARG DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C

RUN apt-get clean && \
    apt-get update --fix-missing && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    dnsutils \
    gnupg \
    libsasl2-modules \
    postgresql-client \
    postfix \
    postfix-pgsql \
    postfix-pcre \
    sasl2-bin \
    supervisor \
    rsyslog \
    net-tools \
    tzdata \
    cron \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN groupadd -g 102 postfix 2>/dev/null || true \
    && groupadd -g 103 postdrop 2>/dev/null || true \
    && useradd -g postfix -u 101 -d /var/spool/postfix -s /usr/sbin/nologin postfix 2>/dev/null || true

COPY postfix.sh /postfix.sh
COPY supervisord.conf /etc/supervisor/supervisord.conf

RUN chmod +x /postfix.sh

RUN mkdir -p /var/spool/postfix /var/log/mail

EXPOSE 25 465 587

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
