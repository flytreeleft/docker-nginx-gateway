#!/bin/sh

crond -c /var/spool/cron/crontabs -b -L /var/log/cron/cron.log

ERROR_PAGES=${EPAGED}
if [[ "$(ls -A "${ERROR_PAGES}" 2>/dev/null)" = "" || "${ENABLE_CUSTOM_ERROR_PAGE}" = "force" ]]; then
    cp -r ${DEFAULT_ERROR_PAGES}/* ${ERROR_PAGES}
    rm -rf ${ERROR_PAGES}/*.conf
fi
case ${ENABLE_CUSTOM_ERROR_PAGE} in
    false)
        rm -rf ${ERROR_PAGES}/01_default.conf
        break
        ;;
    unified)
        cat ${DEFAULT_ERROR_PAGES}/01_unified.conf > ${ERROR_PAGES}/01_default.conf
        break
        ;;
    *)
        cat ${DEFAULT_ERROR_PAGES}/01_default.conf > ${ERROR_PAGES}/01_default.conf
        break
        ;;
esac

LOG=/var/log/letsencrypt/build.log
CMD="/usr/bin/build-certs >> ${LOG} 2>&1; /usr/sbin/nginx -s reload"
# https://github.com/yandex/gixy#usage
if [[ "${DISABLE_GIXY}" != "true" && -e /usr/bin/gixy ]]; then
    # Note: Gixy will search all `include` directives
    CMD="/usr/bin/gixy /etc/nginx/nginx.conf; ${CMD}"
fi
/usr/bin/watch-config -- "${CMD}" &

NGINX=nginx
if [[ "${DEBUG}" = "true" ]]; then
    NGINX=nginx-debug
fi

chown -R nginx /var/log/nginx

eval "${NGINX} -g \"daemon off;\""
