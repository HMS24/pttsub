#!/bin/bash -e

set -o pipefail

# declare
TARGET=""
SSH_PEM=""
DOCKER_USER="local"
DOCKER_PASS=""
IMAGE="ptt_sub"
TAG="latest"

while [[ "$#" -gt 0 ]]; do
	case $1 in
		--target) TARGET="$2"; shift ;;
		--ssh-pem) SSH_PEM="$2"; shift ;;
		--docker-user) DOCKER_USER="$2"; shift ;;
		--docker-pass) DOCKER_PASS="$2"; shift ;;
		--image) IMAGE="$2"; shift ;;
		--tag) TAG="$2"; shift ;;
		*) echo "Unknown parameter passed: $1"; exit 1 ;;
	esac
	shift
done

if [ -z "$TARGET" ]; then
	echo "--target argument is required!"
	exit 1
fi

if [ "$TARGET" != "local" ] && [ -z "$SSH_PEM" ]; then
	echo "--ssh-pem argument is required!"
	exit 1
fi

if [ "$TARGET" != "local" ] && [ "$DOCKER_USER" == "local" ]; then
	echo "--docker-user argument is required!"
	exit 1
fi

if [ "$TARGET" != "local" ] && [ -z "$DOCKER_PASS" ]; then
	echo "--docker-pass argument is required!"
	exit 1
fi

# build
echo "**********************************"
echo "** Building image ****************"
echo "**********************************"

build/build.sh $IMAGE $TAG

# push
echo "**********************************"
echo "** Pushing image *****************"
echo "**********************************"

docker tag $IMAGE:$TAG $DOCKER_USER/$IMAGE:$TAG

if [ "$TARGET" = "local" ];
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

echo "Deploy to $TARGET"

if [ "$TARGET" = "local" ]; 
    then
        DOCKER_USER=$DOCKER_USER \
        IMAGE=$IMAGE \
        TAG=$TAG \
        docker compose up -d
    else
        deploy/deploy.sh $TARGET $SSH_PEM $IMAGE $TAG $DOCKER_USER $DOCKER_PASS
fi

exit 0
