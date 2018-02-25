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

## How to use?

### Image version

The image version is formated as `<nginx version>-<revision number>`, e.g. `1.11.2-r1`, `1.11.2-r2` etc.

### Build image

Run the following commands in the root directory of this git repository:

```bash
IMAGE_NAME=flytreeleft/nginx-gateway
IMAGE_VERSION=1.11.2-r1

docker build --rm -t ${IMAGE_NAME}:${IMAGE_VERSION} .
```

### Create and run

```bash
DCR_NAME=nginx-gateway
DCR_IMAGE=flytreeleft/nginx-gateway
DCR_IMAGE_VERSION=1.11.2-r1

DEBUG=false
ULIMIT=655360
ENABLE_CUSTOM_ERROR_PAGE=true
CERT_EMAIL=nobody@example.com
STORAGE=/var/lib/nginx-gateway

ulimit -n ${ULIMIT}
docker run -d --name ${DCR_NAME} \
                --restart always \
                --network host \
                --ulimit nofile=${ULIMIT} \
                -p 443:443 -p 80:80 \
                -e DEBUG=${DEBUG} \
                -e CERT_EMAIL=${CERT_EMAIL} \
                -e ENABLE_CUSTOM_ERROR_PAGE=${ENABLE_CUSTOM_ERROR_PAGE} \
                -v /usr/share/zoneinfo:/usr/share/zoneinfo:ro \
                -v /etc/localtime:/etc/localtime:ro \
                -v ${STORAGE}/letsencrypt:/etc/letsencrypt \
                -v ${STORAGE}/vhost.d:/etc/nginx/vhost.d \
                -v ${STORAGE}/stream.d:/etc/nginx/stream.d \
                -v ${STORAGE}/epage.d:/etc/nginx/epage.d \
                ${DCR_IMAGE}:${DCR_IMAGE_VERSION}
```

**Note**:
- If you want to use your error pages, just set `ENABLE_CUSTOM_ERROR_PAGE` to `false`, and put your configuration (e.g. [config/error-pages/01_default.conf](./config/error-pages/01_default.conf)) and error pages to `${STORAGE}/epage.d`.
- Mapping `/usr/share/zoneinfo` and `/etc/localtime` from the host machine to make sure the container use the same Time Zone with the host.

## Thanks

- [nginxinc/docker-nginx](https://github.com/nginxinc/docker-nginx/blob/master/stable/alpine/Dockerfile): The official NGINX Dockerfiles based on [alpine image](https://hub.docker.com/_/alpine/).
- [sebble/docker-images/letsencrypt-certbot](https://github.com/sebble/docker-images/tree/master/letsencrypt-certbot): Running [certbot](https://certbot.eff.org/docs/using.html) via crontab.
- [nrollr/nginx.conf](https://gist.github.com/nrollr/9a39bb636a820fb97eec2ed85e473d38): NGINX config for SSL with Let's Encrypt certs.
- [JrCs/docker-letsencrypt-nginx-proxy-companion](https://github.com/JrCs/docker-letsencrypt-nginx-proxy-companion): LetsEncrypt companion container for nginx-proxy.
- [tmthrgd/nginx-status-text.conf](https://gist.github.com/tmthrgd/3504859568e1dba9ee80e260f974a708): Nginx status code to message map.
- [Using NGINX’s X-Accel with Remote URLs](https://www.mediasuite.co.nz/blog/proxying-s3-downloads-nginx/)
- [How to make an existing caching Nginx proxy use another proxy to bypass a firewall?](https://serverfault.com/questions/583743/how-to-make-an-existing-caching-nginx-proxy-use-another-proxy-to-bypass-a-firewa#683955)
- [nginx docker container cannot see client ip when using '--iptables=false' option](http://serverfault.com/questions/786389/nginx-docker-container-cannot-see-client-ip-when-using-iptables-false-option#answer-788088)

## Reference

- [Nginx ssl_stapling](http://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_stapling)
- [Nginx alias](http://nginx.org/en/docs/http/ngx_http_core_module.html#alias): Used to change the directory path of the request file.
- [Nginx sub_filter](http://nginx.org/en/docs/http/ngx_http_sub_module.html#sub_filter): Filter and modify the response body.
- [Nginx error_page](http://nginx.org/en/docs/http/ngx_http_core_module.html#error_page): Define the error page or URI.
- [Nginx random_index](http://nginx.org/en/docs/http/ngx_http_random_index_module.html#random_index): Picks a random file in a directory to serve as an index file.
- [Nginx proxy_intercept_errors](http://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_intercept_errors): Intercept proxy errors and redirected them to nginx for processing with the `error_page` directive.
- [Nginx proxy_hide_header](http://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_hide_header): Hide the headers from the response of a proxied server to a client.
- [Nginx variables](http://nginx.org/en/docs/varindex.html)
