# https://github.com/nginxinc/docker-nginx/blob/master/mainline/alpine/Dockerfile
FROM alpine:3.5
MAINTAINER flytreeleft <flytreeleft@126.com>

ENV LUA_JIT_VERSION 2.0.5
ENV LUA_ROCKS_VERSION 2.4.2
ENV LUA_CJSON_VERSION 2.1.0
ENV LUA_RESTY_STRING_VERSION 0.09
ENV LUA_RESTY_SESSION_VERSION 2.17

#ENV NGINX_VERSION 1.13.1
ENV NGINX_VERSION 1.11.2
ENV NDK_VERSION 0.3.0
ENV NGX_LUA_VERSION 0.10.8

RUN GPG_KEYS=B0F4253373F8F6F510D42178520A9993A1C052F8 \
    && CONFIG="\
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --modules-path=/usr/lib/nginx/modules \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock \
        --http-client-body-temp-path=/var/cache/nginx/client_temp \
        --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
        --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
        --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
        --user=nginx \
        --group=nginx \
        --with-ipv6 \
        --with-http_ssl_module \
        --with-http_realip_module \
        --with-http_addition_module \
        --with-http_sub_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_mp4_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_random_index_module \
        --with-http_secure_link_module \
        --with-http_stub_status_module \
        --with-http_auth_request_module \
        --with-http_xslt_module=dynamic \
        --with-http_image_filter_module=dynamic \
        --with-http_geoip_module=dynamic \
        --with-threads \
        --with-stream \
        --with-stream_ssl_module \
        --with-http_slice_module \
        --with-mail \
        --with-mail_ssl_module \
        --with-file-aio \
        --with-http_v2_module \
    " \
    && addgroup -S nginx \
    && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
    && apk add --no-cache --virtual .build-deps \
        git \
        gcc \
        libc-dev \
        make \
        openssl-dev \
        pcre-dev \
        zlib-dev \
        linux-headers \
        curl \
        gnupg \
        libxslt-dev \
        gd-dev \
        geoip-dev \
    && curl -fSL http://luajit.org/download/LuaJIT-$LUA_JIT_VERSION.tar.gz  -o lua-jit.tar.gz \
    && curl -fSL https://github.com/luarocks/luarocks/archive/v$LUA_ROCKS_VERSION.tar.gz  -o lua-rocks.tar.gz \
    && curl -fSL https://github.com/mpx/lua-cjson/archive/$LUA_CJSON_VERSION.tar.gz  -o lua-cjson.tar.gz \
    && curl -fSL https://github.com/openresty/lua-resty-string/archive/v$LUA_RESTY_STRING_VERSION.tar.gz  -o lua-resty-string.tar.gz \
    && curl -fSL https://github.com/bungle/lua-resty-session/archive/v$LUA_RESTY_SESSION_VERSION.tar.gz -o lua-resty-session.tar.gz \
    && curl -fSL http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tar.gz \
    && curl -fSL http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz.asc  -o nginx.tar.gz.asc \
    && curl -fSL https://github.com/simpl/ngx_devel_kit/archive/v$NDK_VERSION.tar.gz  -o ngx_devel_kit.tar.gz \
    && curl -fSL https://github.com/openresty/lua-nginx-module/archive/v$NGX_LUA_VERSION.tar.gz  -o lua-nginx-module.tar.gz \
    && export GNUPGHOME="$(mktemp -d)" \
    && found=''; \
    for server in \
        ha.pool.sks-keyservers.net \
        hkp://keyserver.ubuntu.com:80 \
        hkp://p80.pool.sks-keyservers.net:80 \
        pgp.mit.edu \
    ; do \
        echo "Fetching GPG key $GPG_KEYS from $server"; \
        gpg --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$GPG_KEYS" && found=yes && break; \
    done; \
    test -z "$found" && echo >&2 "error: failed to fetch GPG key $GPG_KEYS" && exit 1; \
    gpg --batch --verify nginx.tar.gz.asc nginx.tar.gz \
    && rm -r "$GNUPGHOME" nginx.tar.gz.asc \
    && mkdir -p /usr/src \
    && tar -zxC /usr/src -f lua-jit.tar.gz \
    && tar -zxC /usr/src -f lua-rocks.tar.gz \
    && tar -zxC /usr/src -f lua-cjson.tar.gz \
    && tar -zxC /usr/src -f lua-resty-string.tar.gz \
    && tar -zxC /usr/src -f lua-resty-session.tar.gz \
    && tar -zxC /usr/src -f nginx.tar.gz \
    && tar -zxC /usr/src -f ngx_devel_kit.tar.gz \
    && tar -zxC /usr/src -f lua-nginx-module.tar.gz \
    && rm -f *.tar.gz \
    && cd /usr/src/LuaJIT-$LUA_JIT_VERSION \
    && make \
    && make install \
    && ln -sf /usr/local/bin/luajit /usr/local/bin/lua \
    && export LUAJIT_LIB=/usr/local/lib \
    && export LUAJIT_INC=/usr/local/include/luajit-2.0 \
    && cd /usr/src/luarocks-$LUA_ROCKS_VERSION \
    && ./configure --prefix=/usr/local \
            --lua-suffix=jit-$LUA_JIT_VERSION \
            --with-lua=/usr/local \
            --with-lua-include=$LUAJIT_INC \
            --with-lua-lib=$LUAJIT_LIB \
    && make build \
    && make install \
    && cd /usr/src/lua-cjson-$LUA_CJSON_VERSION \
    && make LUA_VERSION=5.1 LUA_INCLUDE_DIR=$LUAJIT_INC \
    && make install \
    && cd /usr/src/lua-resty-string-$LUA_RESTY_STRING_VERSION \
    && make \
    && make install LUA_INCLUDE_DIR=$LUAJIT_INC LUA_LIB_DIR=/usr/local/share/lua/5.1 \
    # Install Lua moduels
    && luarocks install lua-resty-openidc \
    # Fix issue: https://github.com/pingidentity/lua-resty-openidc/wiki#why-does-my-browser-get-in-to-a-redirect-loop
    && cp -r /usr/src/lua-resty-session-$LUA_RESTY_SESSION_VERSION/lib/resty /usr/local/share/lua/5.1 \
    && cd /usr/src/nginx-$NGINX_VERSION \
    && ./configure $CONFIG \
            --with-debug \
            --with-ld-opt="-Wl,-rpath,$LUAJIT_LIB" \
            --add-module=/usr/src/ngx_devel_kit-$NDK_VERSION \
            --add-module=/usr/src/lua-nginx-module-$NGX_LUA_VERSION \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && mv objs/nginx objs/nginx-debug \
    && mv objs/ngx_http_xslt_filter_module.so objs/ngx_http_xslt_filter_module-debug.so \
    && mv objs/ngx_http_image_filter_module.so objs/ngx_http_image_filter_module-debug.so \
    && mv objs/ngx_http_geoip_module.so objs/ngx_http_geoip_module-debug.so \
    && ./configure $CONFIG \
            --with-ld-opt="-Wl,-rpath,$LUAJIT_LIB" \
            --add-module=/usr/src/ngx_devel_kit-$NDK_VERSION \
            --add-module=/usr/src/lua-nginx-module-$NGX_LUA_VERSION \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && make install \
    && rm -rf /etc/nginx/html/ \
    && mkdir /etc/nginx/conf.d/ \
    && mkdir -p /usr/share/nginx/html/ \
    && install -m644 html/index.html /usr/share/nginx/html/ \
    && install -m644 html/50x.html /usr/share/nginx/html/ \
    && install -m755 objs/nginx-debug /usr/sbin/nginx-debug \
    && install -m755 objs/ngx_http_xslt_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_xslt_filter_module-debug.so \
    && install -m755 objs/ngx_http_image_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_image_filter_module-debug.so \
    && install -m755 objs/ngx_http_geoip_module-debug.so /usr/lib/nginx/modules/ngx_http_geoip_module-debug.so \
    && ln -s ../../usr/lib/nginx/modules /etc/nginx/modules \
    && strip /usr/sbin/nginx* \
    && strip /usr/lib/nginx/modules/*.so \
    && rm -rf /usr/src \
    \
    # Bring in gettext so we can get `envsubst`, then throw
    # the rest away. To do this, we need to install `gettext`
    # then move `envsubst` out of the way so `gettext` can
    # be deleted completely, then move `envsubst` back.
    && apk add --no-cache --virtual .gettext gettext \
    && mv /usr/bin/envsubst /tmp/ \
    \
    && runDeps="$( \
        scanelf --needed --nobanner /usr/sbin/nginx /usr/lib/nginx/modules/*.so \
                                    /usr/local/bin/luarocks /usr/local/bin/luajit \
                                    /usr/local/lib/*.so /tmp/envsubst \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | sort -u \
            | xargs -r apk info --installed \
            | sort -u \
    )" \
    && apk add --no-cache --virtual .nginx-rundeps $runDeps \
    && apk del .build-deps \
    && apk del .gettext \
    && mv /tmp/envsubst /usr/local/bin/ \
    \
    # forward request and error logs to docker log collector
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log


ENV DEBUG=false
ENV DOMAIN=
ENV CERT_EMAIL=
ENV ENABLE_CUSTOM_ERROR_PAGE=false
ENV DEFAULT_ERROR_PAGES=/usr/share/nginx/error-pages
ENV VHOSTD=/etc/nginx/vhost.d
ENV STREAMD=/etc/nginx/stream.d
ENV EPAGED=/etc/nginx/epage.d
ENV CERTBOT=/etc/letsencrypt

RUN apk add --update openssl certbot ca-certificates
# Fix issue: https://github.com/Yelp/dumb-init/issues/73
RUN update-ca-certificates
RUN mkdir -p /etc/nginx/ssl && openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048
RUN apk del openssl && rm -rf /var/cache/apk/*

RUN mkdir -p /var/log/cron /var/log/letsencrypt
#RUN mkdir -p /var/www/html && chown -R nginx:nginx /var/www/html
RUN rm -f /etc/nginx/conf.d/default.conf

ADD config/nginx.conf /etc/nginx/nginx.conf
ADD config/00_vars.conf /etc/nginx/conf.d/00_vars.conf
ADD config/01_ssl.conf /etc/nginx/conf.d/01_ssl.conf
ADD config/02_proxy.conf /etc/nginx/conf.d/02_proxy.conf
ADD config/10_default.conf /etc/nginx/conf.d/10_default.conf

# NOTE: The other crontab file will not be scaned
COPY config/crontab /var/spool/cron/crontabs/root

ADD bin/build-certs /usr/bin/build-certs
ADD bin/update-certs /usr/bin/update-certs
ADD bin/watch-config /usr/bin/watch-config
ADD bin/entrypoint.sh /entrypoint.sh

ADD config/error-pages ${DEFAULT_ERROR_PAGES}

RUN mkdir -p ${VHOSTD} ${STREAMD} ${CERTBOT} ${EPAGED}
RUN chmod +x /usr/bin/build-certs /usr/bin/update-certs /usr/bin/watch-config /entrypoint.sh

VOLUME ["${VHOSTD}", "${STREAMD}", "${EPAGED}", "${CERTBOT}"]

EXPOSE 80 443

# CMD & ENTRYPOINT
## https://docs.docker.com/engine/reference/builder/#understand-how-cmd-and-entrypoint-interact
ENTRYPOINT ["/entrypoint.sh"]
