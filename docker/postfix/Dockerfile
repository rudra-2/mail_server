FROM debian:bookworm-slim

LABEL maintainer="Reloop Mail Server"

ARG DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C

# Install required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
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

# Create postfix user and group
RUN groupadd -g 102 postfix \
    && groupadd -g 103 postdrop \
    && useradd -g postfix -u 101 -d /var/spool/postfix -s /usr/sbin/nologin postfix

# Copy configuration files
COPY postfix.sh /postfix.sh
COPY supervisord.conf /etc/supervisor/supervisord.conf

# Make scripts executable
RUN chmod +x /postfix.sh

# Create necessary directories
RUN mkdir -p /var/spool/postfix /var/log/mail

# Expose ports
EXPOSE 25 465 587

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
