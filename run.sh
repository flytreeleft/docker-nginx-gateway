#!/bin/bash

DCR_NAME=nginx-gateway
DCR_IMAGE=flytreeleft/nginx-gateway
DCR_IMAGE_VERSION=1.11.2-r1

DEBUG=false
ULIMIT=655360
CERT_EMAIL=nobody@example.com
STORAGE=/var/lib/nginx-gateway

#ulimit -n ${ULIMIT}
docker rm -f ${DCR_NAME}
# http://serverfault.com/questions/786389/nginx-docker-container-cannot-see-client-ip-when-using-iptables-false-option#answer-788088
docker run -d --name ${DCR_NAME} \
                --restart always \
                --network host \
                --ulimit nofile=${ULIMIT} \
                -p 443:443 -p 80:80 \
                -e DEBUG=${DEBUG} \
                -e CERT_EMAIL=${CERT_EMAIL} \
                -v /usr/share/zoneinfo:/usr/share/zoneinfo:ro \
                -v /etc/localtime:/etc/localtime:ro \
                -v ${STORAGE}/letsencrypt:/etc/letsencrypt \
                -v ${STORAGE}/vhost.d:/etc/nginx/vhost.d \
                -v ${STORAGE}/stream.d:/etc/nginx/stream.d \
                ${DCR_IMAGE}:${DCR_IMAGE_VERSION}
