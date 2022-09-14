#!/bin/bash

set -e
set -o pipefail

export IMAGE=$(sed -n '1p' /tmp/.auth)
export TAG=$(sed -n '2p' /tmp/.auth)
export DOCKER_USER=$(sed -n '3p' /tmp/.auth)
export DOCKER_PASS=$(sed -n '4p' /tmp/.auth)

rm /tmp/.auth

echo "$DOCKER_PASS" > docker login -u $DOCKER_USER --password-stdin

cd ~/ptt && docker compose up -d

exit 0