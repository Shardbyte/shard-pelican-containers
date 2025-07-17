#################################################
# Copyright (c) Shardbyte. All Rights Reserved. #
# SPDX-License-Identifier: MIT                  #
#################################################
#
FROM debian:bookworm-slim

LABEL author="Shardbyte" \
      maintainer="containers@shardbyte.com" \
      org.opencontainers.image.source="https://github.com/Shardbyte/shard-pelican-containers" \
      org.opencontainers.image.description="Application packaged by Shardbyte" \
      org.opencontainers.image.title="arkmanager" \
      org.opencontainers.image.licenses="MIT"

ENV LANG=en_US.UTF-8 \
    USER=container \
    HOME=/home/container

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN echo steam steam/question select "I AGREE" | debconf-set-selections \
    && echo steam steam/license note '' | debconf-set-selections \
    && sed -i 's/^Components: main$/& contrib non-free/' /etc/apt/sources.list.d/debian.sources \
    && sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen

RUN dpkg --add-architecture i386 \
    && apt update \
    && apt -y upgrade \
    && apt install -y --no-install-recommends \
        sed \
        tar \
        lsof \
        gzip \
        bzip2 \
        curl \
        wget \
        cron \
        rsync \
        locales \
        ca-certificates \
        perl \
        perl-base \
        perl-modules \
        coreutils \
        findutils \
        steamcmd \
        lib32gcc-s1 \
        lib32stdc++6 \
        libc6-i386 \
        libcurl4-gnutls-dev:i386 \
        libsdl2-2.0-0:i386 \
    && apt -y autoremove \
    && apt clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN groupadd -g 988 container || true \
    && useradd -m -d /home/container -s /bin/bash -g container container
USER container
WORKDIR /home/container

COPY --chown=container:container entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/bin/bash", "/entrypoint.sh"]