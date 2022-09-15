#!/bin/bash

set -xe
set -o pipefail

REMOTE_MACHINE=$1

echo "$IMAGE" > /tmp/.auth
echo "$TAG" >> /tmp/.auth
echo "$DOCKER_USER" >> /tmp/.auth
cat $DOCKER_PASS >> /tmp/.auth

scp -i $SSH_PEM /tmp/.auth $REMOTE_MACHINE:/tmp/.auth
scp -i $SSH_PEM ./deploy/publish.sh $REMOTE_MACHINE:/tmp/publish.sh
scp -i $SSH_PEM ./compose.yml $REMOTE_MACHINE:~/ptt/compose.yml

ssh -i $SSH_PEM $REMOTE_MACHINE ". /tmp/publish.sh"

exit 0