#!/bin/bash

IMAGE_VERSION=1.11.2-r1
IMAGE_NAME=flytreeleft/nginx-gateway:${IMAGE_VERSION}

docker build --rm -t ${IMAGE_NAME} .
#docker save ${IMAGE_NAME} > nginx-gateway.img.tar

docker push ${IMAGE_NAME}
