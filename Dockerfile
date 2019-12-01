# https://github.com/nginxinc/docker-nginx/blob/master/mainline/alpine/Dockerfile
FROM alpine:3.10
MAINTAINER flytreeleft <flytreeleft@126.com>


ENV LUA_JIT_VERSION 2.1-20190912
ENV LUA_ROCKS_VERSION 3.2.1
ENV LUA_RESTY_LRUCACHE_VERSION 0.09
ENV LUA_RESTY_CORE_VERSION 0.1.17
ENV LUA_RESTY_STRING_VERSION 0.11

ENV NGINX_VERSION 1.15.12
ENV NDK_VERSION 0.3.1
ENV NGX_LUA_VERSION 0.10.15
ENV NGX_GEOIP2_VERSION 2.0

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
        --with-threads \
        --with-stream \
        --with-stream_ssl_module \
        --with-http_slice_module \
        --with-mail \
        --with-mail_ssl_module \
        --with-file-aio \
        --with-http_v2_module \
    " \
    && apk add --update --no-cache openssl ca-certificates \
    && update-ca-certificates \
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
        unzip \
        gnupg \
        libxslt-dev \
        gd-dev \
        libmaxminddb \
        libmaxminddb-dev \
    && curl -fSL https://github.com/openresty/luajit2/archive/v$LUA_JIT_VERSION.tar.gz  -o lua-jit.tar.gz \
    && curl -fSL https://github.com/luarocks/luarocks/archive/v$LUA_ROCKS_VERSION.tar.gz  -o lua-rocks.tar.gz \
    && curl -fSL https://github.com/openresty/lua-resty-lrucache/archive/v$LUA_RESTY_LRUCACHE_VERSION.tar.gz  -o lua-resty-lrucache.tar.gz \
    && curl -fSL https://github.com/openresty/lua-resty-core/archive/v$LUA_RESTY_CORE_VERSION.tar.gz  -o lua-resty-core.tar.gz \
    && curl -fSL https://github.com/openresty/lua-resty-string/archive/v$LUA_RESTY_STRING_VERSION.tar.gz  -o lua-resty-string.tar.gz \
    && curl -fSL http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tar.gz \
    && curl -fSL http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz.asc  -o nginx.tar.gz.asc \
    && curl -fSL https://github.com/simpl/ngx_devel_kit/archive/v$NDK_VERSION.tar.gz  -o ngx_devel_kit.tar.gz \
    && curl -fSL https://github.com/openresty/lua-nginx-module/archive/v$NGX_LUA_VERSION.tar.gz  -o lua-nginx-module.tar.gz \
    && curl -fSL https://github.com/leev/ngx_http_geoip2_module/archive/$NGX_GEOIP2_VERSION.tar.gz  -o ngx_http_geoip2_module.tar.gz \
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
    && tar -zxC /usr/src -f lua-resty-lrucache.tar.gz \
    && tar -zxC /usr/src -f lua-resty-core.tar.gz \
    && tar -zxC /usr/src -f lua-resty-string.tar.gz \
    && tar -zxC /usr/src -f nginx.tar.gz \
    && tar -zxC /usr/src -f ngx_devel_kit.tar.gz \
    && tar -zxC /usr/src -f lua-nginx-module.tar.gz \
    && tar -zxC /usr/src -f ngx_http_geoip2_module.tar.gz \
    && rm -f *.tar.gz \
    && cd /usr/src/luajit2-$LUA_JIT_VERSION \
    && make \
    && make install \
    && ln -sf /usr/local/bin/luajit /usr/local/bin/lua \
    && export LUAJIT_LIB=/usr/local/lib \
    && export LUAJIT_INC=/usr/local/include/luajit-2.1 \
    && cd /usr/src/luarocks-$LUA_ROCKS_VERSION \
    && ./configure --prefix=/usr/local \
            --lua-suffix=jit \
            --with-lua=/usr/local \
            --with-lua-include=$LUAJIT_INC \
            --with-lua-lib=$LUAJIT_LIB \
    && make build \
    && make install \
    && cd /usr/src/lua-resty-string-$LUA_RESTY_STRING_VERSION \
    && make \
    && make install LUA_INCLUDE_DIR=$LUAJIT_INC LUA_LIB_DIR=/usr/local/share/lua/5.1 \
    # Install Lua moduels
    && luarocks install lua-resty-http \
    && luarocks install lua-resty-session \
    && luarocks install lua-resty-jwt \
    && luarocks install lua-resty-openidc \
    && cp -r /usr/src/lua-resty-lrucache-$LUA_RESTY_LRUCACHE_VERSION/lib/* /usr/local/share/lua/5.1 \
    && cp -r /usr/src/lua-resty-core-$LUA_RESTY_CORE_VERSION/lib/* /usr/local/share/lua/5.1 \
    && cd /usr/src/nginx-$NGINX_VERSION \
    && ./configure $CONFIG \
            --with-debug \
            --with-ld-opt="-Wl,-rpath,$LUAJIT_LIB" \
            --add-module=/usr/src/ngx_devel_kit-$NDK_VERSION \
            --add-module=/usr/src/lua-nginx-module-$NGX_LUA_VERSION \
            --add-module=/usr/src/ngx_http_geoip2_module-$NGX_GEOIP2_VERSION \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && mv objs/nginx objs/nginx-debug \
    && mv objs/ngx_http_xslt_filter_module.so objs/ngx_http_xslt_filter_module-debug.so \
    && mv objs/ngx_http_image_filter_module.so objs/ngx_http_image_filter_module-debug.so \
    && ./configure $CONFIG \
            --with-ld-opt="-Wl,-rpath,$LUAJIT_LIB" \
            --add-module=/usr/src/ngx_devel_kit-$NDK_VERSION \
            --add-module=/usr/src/lua-nginx-module-$NGX_LUA_VERSION \
            --add-module=/usr/src/ngx_http_geoip2_module-$NGX_GEOIP2_VERSION \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && make install \
    # Note: Keep the '/etc/nginx/html' to prevent 'testing "/etc/nginx/html" existence failed' error
    #&& rm -rf /etc/nginx/html/
    && mkdir /etc/nginx/conf.d/ \
    && mkdir -p /usr/share/nginx/html/ \
    && install -m644 html/index.html /usr/share/nginx/html/ \
    && install -m644 html/50x.html /usr/share/nginx/html/ \
    && install -m755 objs/nginx-debug /usr/sbin/nginx-debug \
    && install -m755 objs/ngx_http_xslt_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_xslt_filter_module-debug.so \
    && install -m755 objs/ngx_http_image_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_image_filter_module-debug.so \
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
    #&& ln -sf /dev/stdout /var/log/nginx/access.log
    && ln -sf /dev/stderr /var/log/nginx/error.log


# Fix issue "wget: can't execute 'ssl_helper'": https://github.com/Yelp/dumb-init/issues/73
RUN apk add --update --no-cache certbot \
    && ln -s /usr/bin/python3 /usr/bin/python
# https://github.com/docker-library/python/blob/master/3.7/alpine3.7/Dockerfile
RUN set -ex; \
	wget -O get-pip.py 'https://bootstrap.pypa.io/get-pip.py'; \
	python get-pip.py \
		--no-cache-dir \
	; \
	pip --version; \
	find /usr/local -depth \
		\( \
			\( -type d -a \( -name test -o -name tests \) \) \
			-o \
			\( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
		\) -exec rm -rf '{}' +; \
	rm -f get-pip.py


ARG enable_geoip=false
# https://github.com/leev/ngx_http_geoip2_module
# http://www.treselle.com/blog/nginx-with-geoip2-maxmind-database-to-fetch-user-geo-location-data/
# https://dev.maxmind.com/geoip/geoip2/geolite2/
RUN [[ "${enable_geoip}" = "true" ]] \
    && mkdir -p /etc/nginx/geoip2 /tmp/geoip2 \
    && cd /tmp/geoip2 \
    && wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz \
            http://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.tar.gz \
    && tar -zxf GeoLite2-City.tar.gz \
    && tar -zxf GeoLite2-Country.tar.gz \
    && find . -name "*.mmdb" -type f -exec mv {} /etc/nginx/geoip2 \; \
    && cd - && rm -rf /tmp/geoip2 \
    ; echo ""
# https://github.com/dauer/geohash/blob/master/lua/README.md
RUN [[ "${enable_geoip}" = "true" ]] \
    && luarocks install https://github.com/dauer/geohash/raw/master/lua/geohash-0.9-1.rockspec \
    ; echo ""


ARG enable_gixy=true
# https://github.com/yandex/gixy
RUN [[ "${enable_gixy}" = "true" ]] && pip install gixy


ENV DEBUG=false
ENV DOMAIN=
ENV CERT_EMAIL=
ENV ENABLE_CUSTOM_ERROR_PAGE=false
ENV DEFAULT_ERROR_PAGES=/usr/share/nginx/error-pages
ENV VHOSTD=/etc/nginx/vhost.d
ENV STREAMD=/etc/nginx/stream.d
ENV EPAGED=/etc/nginx/epage.d
ENV CERTBOT=/etc/letsencrypt
ENV NGINX_LOG=/var/log/nginx
ENV NGINX_SITES_LOG=/var/log/nginx/sites

RUN mkdir -p /etc/nginx/ssl && openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048
RUN rm -rf /root/.cache

RUN mkdir -p /var/log/cron /var/log/letsencrypt ${NGINX_LOG} ${NGINX_SITES_LOG}
#RUN mkdir -p /var/www/html && chown -R nginx:nginx /var/www/html
RUN rm -f /etc/nginx/conf.d/default.conf

ADD config/nginx.conf /etc/nginx/nginx.conf
ADD config/00_vars.conf /etc/nginx/conf.d/00_vars.conf
ADD config/00_log.conf /etc/nginx/conf.d/00_log.conf
ADD config/01_ssl.conf /etc/nginx/conf.d/01_ssl.conf
ADD config/02_proxy.conf /etc/nginx/conf.d/02_proxy.conf
ADD config/03_geoip2.conf /etc/nginx/conf.d/03_geoip2.conf
ADD config/00_log_with_geoip.conf /etc/nginx/conf.d/00_log_with_geoip.conf
ADD config/10_default.conf /etc/nginx/conf.d/10_default.conf

# NOTE: The other crontab file will not be scaned
COPY config/crontab /var/spool/cron/crontabs/root

ADD bin/build-certs /usr/bin/build-certs
ADD bin/update-certs /usr/bin/update-certs
ADD bin/watch-config /usr/bin/watch-config
ADD bin/entrypoint.sh /entrypoint.sh

ADD config/error-pages ${DEFAULT_ERROR_PAGES}

RUN [[ "${enable_geoip}" != "true" ]] \
    && rm -f /etc/nginx/conf.d/*geoip* \
    ; echo ""
RUN mkdir -p ${VHOSTD} ${STREAMD} ${CERTBOT} ${EPAGED}
RUN chmod +x /usr/bin/build-certs /usr/bin/update-certs /usr/bin/watch-config /entrypoint.sh

VOLUME ["${VHOSTD}", "${STREAMD}", "${EPAGED}", "${CERTBOT}"]

EXPOSE 80 443

# CMD & ENTRYPOINT
## https://docs.docker.com/engine/reference/builder/#understand-how-cmd-and-entrypoint-interact
ENTRYPOINT ["/entrypoint.sh"]
