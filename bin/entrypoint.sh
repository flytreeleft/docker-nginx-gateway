#!/bin/bash

ERROR_PAGES=${EPAGED}
if [[ "$(ls -A "${ERROR_PAGES}" 2>/dev/null)" = "" || "${ENABLE_CUSTOM_ERROR_PAGE}" = "force" ]]; then
    cp -r ${DEFAULT_ERROR_PAGES}/* ${ERROR_PAGES}
    rm -rf ${ERROR_PAGES}/*.conf
fi
case ${ENABLE_CUSTOM_ERROR_PAGE} in
    false)
        rm -rf ${ERROR_PAGES}/01_default.conf
        ;;
    unified)
        cat ${DEFAULT_ERROR_PAGES}/01_unified.conf > ${ERROR_PAGES}/01_default.conf
        ;;
    *)
        cat ${DEFAULT_ERROR_PAGES}/01_default.conf > ${ERROR_PAGES}/01_default.conf
        ;;
esac


if [[ ! -d "/opt/acme.sh" && "${DISABLE_CERTBOT}" != "true" ]]; then
    pushd /opt/acme.sh-src
        # https://github.com/acmesh-official/acme.sh
        bash ./acme.sh \
            --install  \
            --home /opt/acme.sh \
            --config-home "${CERT_DIR}/config" \
            --cert-home "${CERT_DIR}/certs" \
            --nocron \
            --log \
            --debug 2>/dev/null \
        && ln -sf /opt/acme.sh/acme.sh /usr/bin/acme.sh \
        && chmod +x /opt/acme.sh/acme.sh /usr/bin/acme.sh
    popd
fi

if [[ "${DISABLE_CERTBOT}" = "true" || "${CERT_CHALLENGE_TYPE}" != "alpn" ]]; then
    rm -f /etc/nginx/vstream.d/10_stream_acme.conf
fi
if [[ "${DISABLE_CERTBOT}" = "true" || "${CERT_CHALLENGE_TYPE}" = "dns" ]]; then
    # Cancel automically updating
    rm -f /var/spool/cron/crontabs/root
fi


# https://github.com/yandex/gixy#usage
if [[ "${DISABLE_GIXY}" != "true" && -e /usr/bin/gixy ]]; then
    # Note: Gixy will search all `include` directives
    /usr/bin/gixy /etc/nginx/nginx.conf
fi


CERT_BUILD_CMD="/usr/sbin/nginx -s reload"
if [[ "${DISABLE_CERTBOT}" != "true" && "${CERT_CHALLENGE_TYPE}" != "dns" ]]; then
    CERT_BUILD_CMD="/usr/bin/build-certs >> '${CERT_DIR}/build.log' 2>&1; ${CERT_BUILD_CMD}"
fi
/usr/bin/watch-config -- "${CERT_BUILD_CMD}" &


NGINX=nginx
if [[ "${DEBUG}" = "true" ]]; then
    NGINX=nginx-debug
fi

chown -R nginx /var/log/nginx

eval "${NGINX} -g \"daemon off;\""
