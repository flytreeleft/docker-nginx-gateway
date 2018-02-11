#!/bin/bash

IMAGE_NAME=flytreeleft/nginx-gateway
IMAGE_VERSION=1.11.2

docker build --rm -t ${IMAGE_NAME}:${IMAGE_VERSION} .
#docker save ${IMAGE_NAME}:${IMAGE_VERSION} > nginx-gateway.img.tar

docker push ${IMAGE_NAME}:${IMAGE_VERSION}
