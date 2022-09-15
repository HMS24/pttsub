#!/bin/bash

set -e
set -o pipefail

DEPLOY_PLACE=$1

export SSH_PEM=$2
export DOCKER_USER=${3:-"local"}
export DOCKER_PASS=$4
export IMAGE=${5:-"ptt_sub"}
export TAG=${6:-"latest"}

if [ -z "$DEPLOY_PLACE" ]; then
	echo "DEPLOY_PLACE argument is required!"
	exit 1
fi

if [ "$DEPLOY_PLACE" != "local" ] && [ -z "$SSH_PEM" ]; then
	echo "SSH_PEM argument is required!"
	exit 1
fi

if [ "$DEPLOY_PLACE" != "local" ] && [ "$DOCKER_USER" == "local" ]; then
	echo "DOCKER_USER argument is required!"
	exit 1
fi

if [ "$DEPLOY_PLACE" != "local" ] && [ -z "$DOCKER_PASS" ]; then
	echo "DOCKER_PASS argument is required!"
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

if [ "$DEPLOY_PLACE" = "local" ];
    then
        true
    else
        docker login -u $DOCKER_USER --password-stdin < $DOCKER_PASS
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
