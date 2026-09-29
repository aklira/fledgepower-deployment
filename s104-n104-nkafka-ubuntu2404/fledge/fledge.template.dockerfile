FROM ubuntu:24.04

LABEL author="Akli Rahmoun"

# Set Fledge component versions
ARG GITHEAD=GITHEAD
ARG FLEDGEDISPATCHERVERSION=FLEDGEDISPATCHERVERSION
ARG FLEDGENOTIFVERSION=FLEDGENOTIFVERSION

ENV FLEDGE_ROOT=/usr/local/fledge

# Avoid interactive questions when installing Kerberos
ENV DEBIAN_FRONTEND=noninteractive

# ca-certificates is required for HTTPS downloads from GitHub.
RUN apt-get update && apt-get dist-upgrade -y && apt-get install --no-install-recommends --yes \
    git \
    ca-certificates \
    curl \
    unzip \
    sudo \
    iputils-ping \
    inetutils-telnet \
    nano \
    rsyslog \
    sed \
    wget \
    jq \
    cmake g++ make build-essential autoconf automake uuid-dev \
    libssl-dev zlib1g-dev pkg-config libcurl4-openssl-dev libboost-dev && \
    echo '=============================================='

COPY fledge-install-core.sh /tmp/

RUN chmod +x /tmp/fledge-install-core.sh && \
    /tmp/fledge-install-core.sh ${GITHEAD} && \
    echo '=============================================='

COPY fledge-install-include.sh /tmp/

RUN chmod +x /tmp/fledge-install-include.sh && \
    /tmp/fledge-install-include.sh && \
    echo '=============================================='

COPY fledge-install-dispatcher.sh /tmp/

RUN chmod +x /tmp/fledge-install-dispatcher.sh && \
    /tmp/fledge-install-dispatcher.sh ${FLEDGEDISPATCHERVERSION} && \
    echo '=============================================='

COPY fledge-install-notification.sh /tmp/

RUN chmod +x /tmp/fledge-install-notification.sh && \
    /tmp/fledge-install-notification.sh ${FLEDGENOTIFVERSION} && \
    echo '=============================================='

# Hotfix for uppercase ssl certificate, can be removed after integrating Fledge >= 2.7.0 (including commit 9d8bc89)
RUN sed -i '/username =.*commonName/ s/ *$/.lower()/' "/usr/local/fledge/python/fledge/services/core/api/auth.py"

# INSERT MODULES TO BUILD HERE

WORKDIR /usr/local/fledge

COPY importModules.sh importModules.sh
COPY start.sh start.sh

# REMOVE SOURCES IN /tmp
RUN rm -rf /tmp/*

RUN chmod +x start.sh
VOLUME /usr/local/fledge

# INSERT PORT LIST HERE
EXPOSE 8081 8090 1995 8080 2404

# start rsyslog, FLEDGE, and tail syslog
CMD ["/bin/bash","/usr/local/fledge/start.sh"]
