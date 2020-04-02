#!/bin/sh

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

CERT_BUILD_CMD="/usr/sbin/nginx -s reload"
if [[ "${DISABLE_CERTBOT}" != "true" ]]; then
    /usr/bin/python3 /usr/bin/acme-responder.py >> "${CERT_DIR}/acme-responder.log" 2>&1 &
    echo "Wait ACME Responder to be ready ..." && sleep 5s

    CERT_BUILD_CMD="/usr/bin/build-certs >> '${CERT_DIR}/build.log' 2>&1; ${CERT_BUILD_CMD}"
    # First running
    eval "sleep 5s; ${CERT_BUILD_CMD}" &
fi
/usr/bin/watch-config -- "${CERT_BUILD_CMD}" &

# https://github.com/yandex/gixy#usage
if [[ "${DISABLE_GIXY}" != "true" && -e /usr/bin/gixy ]]; then
    # Note: Gixy will search all `include` directives
    /usr/bin/gixy /etc/nginx/nginx.conf
fi

NGINX=nginx
if [[ "${DEBUG}" = "true" ]]; then
    NGINX=nginx-debug
fi

chown -R nginx /var/log/nginx

eval "${NGINX} -g \"daemon off;\""
