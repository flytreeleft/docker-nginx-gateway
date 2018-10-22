Nginx Gateway
===============================

A tiny, flexable, configurable Nginx Gateway (reverse proxy) Docker image based on [alpine image](https://hub.docker.com/_/alpine/).

## Features

- Enable HTTPS and [OCSP Stapling](https://tools.ietf.org/html/rfc4366#section-3.6) with [Let’s Encrypt](https://letsencrypt.org/).
- Automatically register [Let’s Encrypt](https://letsencrypt.org/) certificate for new domain and update certificates via [certbot](https://certbot.eff.org/docs/using.html).
- Support to display your custom error pages randomly.
- Support to load and execute [Lua](https://github.com/openresty/lua-nginx-module) codes.
- Support to proxy HTTP and TCP stream.
- Make individual configuration for every domain to serve static files or to proxy the backend servers.
- Support to create multiple pod replicas in k8s.
- Support access log rotation, e.g. `access_2018-04-26.log`.
- Support authentication with OpenID (via [lua-resty-openidc](https://github.com/zmartzone/lua-resty-openidc)) and to add client IPs to the non-auth whitelist.
- Enable building image with [GeoIp2](https://github.com/leev/ngx_http_geoip2_module) or not.
- Integrated with [Gixy](https://github.com/yandex/gixy) to analyze Nginx configuration to prevent security misconfiguration and automate flaw detection.

## How to use?

### Image version

The image version is formated as `<nginx version>-r<revision number>[p<patch number>]`, e.g. `1.11.2-r1`, `1.11.2-r1p1`, `1.11.2-r2` etc.

### Build image

Run the following commands in the root directory of this git repository:

```bash
IMAGE_VERSION=1.11.2-r2
IMAGE_NAME=flytreeleft/nginx-gateway:${IMAGE_VERSION}

docker build --rm -t ${IMAGE_NAME} .
```

If you want to enable [GeoIp2](https://github.com/leev/ngx_http_geoip2_module), just set the build argument `enable_geoip` to `true`:

```bash
IMAGE_VERSION=1.11.2-r2
IMAGE_NAME=flytreeleft/nginx-gateway-with-geoip:${IMAGE_VERSION}

docker build --rm --build-arg enable_geoip=true -t ${IMAGE_NAME} .
```

### Create and run

```bash
DCR_IMAGE_VERSION=1.11.2-r2

DCR_NAME=nginx-gateway
DCR_IMAGE=flytreeleft/nginx-gateway:${DCR_IMAGE_VERSION}

DCR_VOLUME=/var/lib/nginx-gateway

DEBUG=false
ULIMIT=655360
ENABLE_CUSTOM_ERROR_PAGE=true
CERT_EMAIL=nobody@example.com

ulimit -n ${ULIMIT}
docker run -d --name ${DCR_NAME} \
                --restart always \
                --network host \
                --ulimit nofile=${ULIMIT} \
                -p 443:443 -p 80:80 \
                -e DEBUG=${DEBUG} \
                -e CERT_EMAIL=${CERT_EMAIL} \
                -e ENABLE_CUSTOM_ERROR_PAGE=${ENABLE_CUSTOM_ERROR_PAGE} \
                -e DISABLE_GIXY=false \
                -v /usr/share/zoneinfo:/usr/share/zoneinfo:ro \
                -v /etc/localtime:/etc/localtime:ro \
                -v ${DCR_VOLUME}/logs:/var/log/nginx/sites \
                -v ${DCR_VOLUME}/letsencrypt:/etc/letsencrypt \
                -v ${DCR_VOLUME}/vhost.d:/etc/nginx/vhost.d \
                -v ${DCR_VOLUME}/stream.d:/etc/nginx/stream.d \
                -v ${DCR_VOLUME}/epage.d:/etc/nginx/epage.d \
                ${DCR_IMAGE}
```

**Note**:
- If you want to use your error pages, just set `ENABLE_CUSTOM_ERROR_PAGE` to `false`, and put your configuration (e.g. [config/error-pages/01_default.conf](./config/error-pages/01_default.conf)) and error pages to `${STORAGE}/epage.d`.
- Mapping `/usr/share/zoneinfo` and `/etc/localtime` from the host machine to make sure the container use the same Time Zone with the host.
- The access and error log will be put in the directory `/var/log/nginx/sites/{domain}`. The access log file will be named as `access_{date}.log` (e.g. `access_2018-04-26.log`), and the error log will be named as `error.log`.
- Set `DISABLE_GIXY` to `true` if you don't want to run Gixy to check Nginx configuration files when they are changed.

## How to configure your site?

There are some examples in [examples/vhost.d](./examples/vhost.d) for different needs.

In [config/10_default.conf](./config/10_default.conf), all HTTP requests will be redirected to HTTPS,
so you just need to listen on `443` and configure for you HTTPS site which is like the following codes:
```nginx
server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name <your-domain>;

    # Note: The additional configuration files (for ssl, log, etc.) which are generated automatically
    # will be put into the fixed location as '/etc/nginx/vhost.d/<your-domain>',
    # so do not change it.
    include /etc/nginx/vhost.d/<your-domain>/*.conf;

    location / {
        # Avoid to get address resolve error when starting
        set $target http://<proxy to backend>:80;
        proxy_pass  $target;
    }
}
```

Also, you can put the global and default settings in one file (e.g. [vhost.d/00_default.conf](./examples/vhost.d/00_default.conf)),
just make sure it will be loaded before the other site configuration files. Here are some usefull configurations:
```nginx
resolver 8.8.8.8 valid=300s;
resolver_timeout 5s;

# Websocket support
proxy_http_version 1.1;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";

# Force to change the redirect url's scheme to https
proxy_redirect   http:// $scheme://;
proxy_redirect     / /;
```

For other needs, see details in:
- [Enable upload big files to your site](./examples/vhost.d/git.example.com.conf)
- [The Nexus3 repository sites for Docker images and the library packages of Maven, NPM, etc.](./examples/vhost.d/repo.example.com.conf)
- [Proxy the static files behind the firewall](./examples/vhost.d/static.example.com.conf)
- [Enable the HTTP Basic Authentication or OpenID](./examples/vhost.d/wiki.example.com.conf)
- [Proxy the TCP streams](./examples/stream.d/mysql.conf)

## Thanks

- [nginxinc/docker-nginx](https://github.com/nginxinc/docker-nginx/blob/master/stable/alpine/Dockerfile): The official NGINX Dockerfiles based on [alpine image](https://hub.docker.com/_/alpine/).
- [sebble/docker-images/letsencrypt-certbot](https://github.com/sebble/docker-images/tree/master/letsencrypt-certbot): Running [certbot](https://certbot.eff.org/docs/using.html) via crontab.
- [nrollr/nginx.conf](https://gist.github.com/nrollr/9a39bb636a820fb97eec2ed85e473d38): NGINX config for SSL with Let's Encrypt certs.
- [JrCs/docker-letsencrypt-nginx-proxy-companion](https://github.com/JrCs/docker-letsencrypt-nginx-proxy-companion): LetsEncrypt companion container for nginx-proxy.
- [tmthrgd/nginx-status-text.conf](https://gist.github.com/tmthrgd/3504859568e1dba9ee80e260f974a708): Nginx status code to message map.
- [Using NGINX’s X-Accel with Remote URLs](https://www.mediasuite.co.nz/blog/proxying-s3-downloads-nginx/)
- [How to make an existing caching Nginx proxy use another proxy to bypass a firewall?](https://serverfault.com/questions/583743/how-to-make-an-existing-caching-nginx-proxy-use-another-proxy-to-bypass-a-firewa#683955)
- [nginx docker container cannot see client ip when using '--iptables=false' option](http://serverfault.com/questions/786389/nginx-docker-container-cannot-see-client-ip-when-using-iptables-false-option#answer-788088)
- [Log rotation directly within Nginx configuration file](https://www.cambus.net/log-rotation-directly-within-nginx-configuration-file/): Using variables in `access_log` directives to rotate access log. Note: embed variables can not be used in `error_log` directives.
- [Log rotation directly within Nginx configuration file: map instead of if](https://github.com/fcambus/nginx-resources/issues/12): Using `map` directives instead of `if` for rotating access log.
- [zmartzone/lua-resty-openidc](https://github.com/zmartzone/lua-resty-openidc): Give a way to enable OpenID authentication for Nginx.
- [Gixy](https://github.com/yandex/gixy): A tool to analyze Nginx configuration to prevent security misconfiguration.

## Reference

- [Nginx ssl_stapling](http://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_stapling)
- [Nginx alias](http://nginx.org/en/docs/http/ngx_http_core_module.html#alias): Used to change the directory path of the request file.
- [Nginx sub_filter](http://nginx.org/en/docs/http/ngx_http_sub_module.html#sub_filter): Filter and modify the response body.
- [Nginx error_page](http://nginx.org/en/docs/http/ngx_http_core_module.html#error_page): Define the error page or URI.
- [Nginx random_index](http://nginx.org/en/docs/http/ngx_http_random_index_module.html#random_index): Picks a random file in a directory to serve as an index file.
- [Nginx proxy_intercept_errors](http://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_intercept_errors): Intercept proxy errors and redirected them to nginx for processing with the `error_page` directive.
- [Nginx proxy_hide_header](http://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_hide_header): Hide the headers from the response of a proxied server to a client.
- [Nginx variables](http://nginx.org/en/docs/varindex.html)
- [Nginx log_format&access_log](http://nginx.org/en/docs/http/ngx_http_log_module.html)
