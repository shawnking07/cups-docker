FROM debian:buster-slim
MAINTAINER Jacob Alberty <jacob.alberty@foundigital.com>

ARG DEBIAN_FRONTEND=noninteractive
ARG CUPS_VERSION=2.4.0
ARG FILTERS_VERSION=1.28.10
ARG QPDF_VERSION=10.5.0

ENV PREFIX=/usr/local/docker
ENV VOLUME=/config

COPY patches /home/patches

COPY build.sh ./build.sh
COPY fakePkg.sh ${PREFIX}/bin/fakePkg.sh
COPY docker-entrypoint.sh ${PREFIX}/bin/docker-entrypoint.sh
COPY docker-healthcheck.sh ${PREFIX}/bin/docker-healthcheck.sh
COPY drivers ${PREFIX}/share/drivers
COPY functions ${PREFIX}/functions
COPY pre_build /usr/local/docker/pre_build
RUN chmod +x \
    ${PREFIX}/bin/docker-entrypoint.sh \
    ${PREFIX}/bin/docker-healthcheck.sh \
    ${PREFIX}/share/drivers/*.sh \
    ${PREFIX}/functions \
 && chmod -R +x /usr/local/docker/pre_build

RUN chmod +x ./build.sh ${PREFIX}/bin/fakePkg.sh && \
    sync && \
    ./build.sh && \
    rm -f ./build.sh \
    cupsctl --remote-admin --remote-any --share-printers && \
	useradd \
    --groups=sudo,lp,lpadmin --create-home --home-dir=/home/print \
    --shell=/bin/bash \
    --password=$(mkpasswd print) \
    print && \
    sed -i '/%sudo[[:space:]]/ s/ALL[[:space:]]*$/NOPASSWD:ALL/' /etc/sudoers

VOLUME ["/config"]

EXPOSE 631/tcp 631/udp


HEALTHCHECK CMD ${PREFIX}/bin/docker-healthcheck.sh

ENTRYPOINT ${PREFIX}/bin/docker-entrypoint.sh /usr/sbin/cupsd -f
