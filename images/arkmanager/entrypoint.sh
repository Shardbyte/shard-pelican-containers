#!/bin/bash
#################################################
# Copyright (c) Shardbyte. All Rights Reserved. #
# SPDX-License-Identifier: MIT                  #
#################################################
# base installation script

if [ -e "stop-install-loop.sh" ]; then
    echo "Installation already completed, skipping..." >&2
else
    echo "Installing Ark Server Tools..."
    if curl -sL https://raw.githubusercontent.com/arkmanager/ark-server-tools/master/netinstall.sh | bash -s container --me --perform-user-install --yes-i-really-want-to-perform-a-user-install; then
        if cp /home/container/bin/arkmanager /home/container/arkmanager; then
            echo "Creating install completion marker..." | tee stop-install-loop.sh > /dev/null
            echo "Ark Server Tools installation completed successfully"
        else
            echo "Failed to copy arkmanager binary" >&2
            exit 1
        fi
    else
        echo "Failed to install Ark Server Tools" >&2
        exit 1
    fi
fi

MODIFIED_STARTUP=$(eval echo $(echo ./arkmanager ${STARTUP} --verbose | sed -e 's/{{/${/g' -e 's/}}/}/g'))
echo ":/home/container$ ${MODIFIED_STARTUP}"

${MODIFIED_STARTUP}
/bin/bash