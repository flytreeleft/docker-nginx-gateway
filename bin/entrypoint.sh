#!/bin/sh

crond -c /var/spool/cron/crontabs -b -L /var/log/cron/cron.log

LOG=/var/log/letsencrypt/build.log
CMD="/usr/bin/build-certs >> ${LOG} 2>&1; /usr/sbin/nginx -s reload"
/usr/bin/watch-config -- "${CMD}" &

NGINX=nginx
if [[ "$DEBUG" = "true" ]]; then
    NGINX=nginx-debug
fi

eval "$NGINX -g \"daemon off;\""
