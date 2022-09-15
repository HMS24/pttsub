#!/bin/bash

set -e
set -o pipefail

DEPLOY_PLACE=$1

# replace ********
export DOCKER_USER=********
export IMAGE=ptt_sub
export TAG=********
export SSH_PEM=********

if [ -z "$DEPLOY_PLACE" ]; then
	echo "DEPLOY_PLACE argument is required!"
	exit 1
fi

# build
echo "**********************************"
echo "** Building image ****************"
echo "**********************************"

build/build.sh

# push
echo "**********************************"
echo "** Pushing image *****************"
echo "**********************************"

docker tag $IMAGE:$TAG $DOCKER_USER/$IMAGE:$TAG

if [ "$DEPLOY_PLACE" != "local" ];
    then
        docker login -u $DOCKER_USER --password-stdin < ~/docker_pass
        docker push $DOCKER_USER/$IMAGE:$TAG
fi

# deploy
echo "**********************************"
echo "** Deploying *********************"
echo "**********************************"

echo "Deploy to $DEPLOY_PLACE"

if [ "$DEPLOY_PLACE" = "local" ]; 
    then
        docker compose up -d
    else
        deploy/deploy.sh $DEPLOY_PLACE
fi

exit 0
