#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "${DIR}/config.sh"


docker build \
        -t ${IMAGE_NAME}:${IMAGE_VERSION} \
        -f "${DIR}/Dockerfile" \
        "${DIR}" \
    && docker tag ${IMAGE_NAME}:${IMAGE_VERSION} ${IMAGE_NAME}
#docker save ${IMAGE_NAME}:${IMAGE_VERSION} > nginx-gateway.img.tar
#docker push ${IMAGE_NAME}:${IMAGE_VERSION} && docker push ${IMAGE_NAME}

docker build \
        --build-arg enable_geoip=true \
        -t ${IMAGE_GEOIP_NAME}:${IMAGE_VERSION} \
        -f "${DIR}/Dockerfile" \
        "${DIR}" \
    && docker tag ${IMAGE_GEOIP_NAME}:${IMAGE_VERSION} ${IMAGE_GEOIP_NAME}
#docker save ${IMAGE_GEOIP_NAME}:${IMAGE_VERSION} > nginx-gateway-with-geoip.img.tar
#docker push ${IMAGE_GEOIP_NAME}:${IMAGE_VERSION} && docker push ${IMAGE_GEOIP_NAME}
