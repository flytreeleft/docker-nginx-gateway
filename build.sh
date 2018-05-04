#!/bin/bash

IMAGE_VERSION=1.11.2-r2
IMAGE_NAME=flytreeleft/nginx-gateway

docker build --rm -t ${IMAGE_NAME}:${IMAGE_VERSION} .
#docker save ${IMAGE_NAME}:${IMAGE_VERSION} > nginx-gateway.img.tar
#docker push ${IMAGE_NAME}:${IMAGE_VERSION}

docker build --rm --build-arg enable_geoip=true -t ${IMAGE_NAME}-with-geoip:${IMAGE_VERSION} .
#docker save ${IMAGE_NAME}-with-geoip:${IMAGE_VERSION} > nginx-gateway-with-geoip.img.tar
#docker push ${IMAGE_NAME}-with-geoip:${IMAGE_VERSION}
