#################################################
# Copyright (c) Shardbyte. All Rights Reserved. #
# SPDX-License-Identifier: MIT                  #
#################################################

FROM shardbyte/steamcmd

LABEL author="Shardbyte" \
      maintainer="containers@shardbyte.com" \
      org.opencontainers.image.source="https://github.com/Shardbyte/shard-pelican-containers" \
      org.opencontainers.image.description="ARK: Survival Evolved Server for Pelican Panel" \
      org.opencontainers.image.title="pelican-ark" \
      org.opencontainers.image.licenses="MIT"

ARG DEBIAN_FRONTEND=noninteractive

# Pelican Panel specific environment variables
ENV STARTUP_DONE="false" \
    HOME="/home/container" \
    DEBIAN_FRONTEND=noninteractive \
    USER=container \
    STEAM_USER=container \
    STEAM_HOME="/home/container" \
    STEAMCMDDIR="/home/container/steamcmd"
USER root

# Create container user for Pelican Panel
RUN useradd -d /home/container -m container

# Install required packages and ARK server dependencies
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
        curl \
        lib32gcc-s1 \
        lib32stdc++6 \
        libc6-i386 \
        libcurl4-gnutls-dev:i386 \
        ca-certificates \
        jq \
        tzdata \
        iproute2 \
        procps \
        tini \
        perl \
        perl-modules \
        lsof \
        rsync \
        bzip2 \
        cron && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create necessary directories with proper permissions
RUN mkdir -p /home/container/steamcmd /home/container/.steam/sdk32 /home/container/arkserver && \
    chown -R container:container /home/container

# Install arkmanager
ARG ARK_TOOLS_VERSION="latest"
RUN if [ "${ARK_TOOLS_VERSION}" = "latest" ]; then \
        DOWNLOAD_VERSION=$(curl -s https://api.github.com/repos/arkmanager/ark-server-tools/releases/latest | jq -r '.tag_name' | sed 's/^v//'); \
    else \
        DOWNLOAD_VERSION="${ARK_TOOLS_VERSION}"; \
    fi && \
    echo "Installing ARK server tools version: ${DOWNLOAD_VERSION}" && \
    curl -fsSL "https://github.com/arkmanager/ark-server-tools/archive/v${DOWNLOAD_VERSION}.tar.gz" | \
        tar xzf - -C /tmp/ && \
    cd "/tmp/ark-server-tools-${DOWNLOAD_VERSION}/tools" && \
    bash install.sh container && \
    ln -s /usr/local/bin/arkmanager /usr/bin/arkmanager && \
    rm -rf /tmp/ark-server-tools-*

# Copy configuration templates and entrypoint
COPY --chown=container:container entrypoint.sh /entrypoint.sh
COPY --chown=container:container conf/ /home/container/conf/

# Make entrypoint executable
RUN chmod +x /entrypoint.sh

USER container
WORKDIR /home/container

# Install SteamCMD
RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - -C steamcmd && \
    steamcmd/steamcmd.sh +quit

EXPOSE 7777/udp 7778/udp 27015/udp 27020/tcp

ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]
