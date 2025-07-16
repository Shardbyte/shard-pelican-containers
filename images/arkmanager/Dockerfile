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
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    USER=container \
    HOME=/home/container

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
        locales \
        ca-certificates \
        perl \
        perl-base \
        perl-modules \
        coreutils \
        findutils \
        libc6-i386 \
        lib32gcc-s1 \
        lib32stdc++6 \
    && apt -y autoremove \
    && apt clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen

RUN useradd -m -d /home/container -s /bin/bash container
USER container
WORKDIR /home/container

COPY --chown=container:container entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
CMD ["/bin/bash", "/entrypoint.sh"]