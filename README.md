Nginx Gateway
===============================

A tiny, flexable, configurable Nginx gateway (reverse proxy) Docker image based on the [alpine image](https://hub.docker.com/_/alpine/).

## Features

- Enable HTTPS and [OCSP Stapling](https://tools.ietf.org/html/rfc4366#section-3.6) with [Let’s Encrypt](https://letsencrypt.org/).
- Automatically register [Let’s Encrypt](https://letsencrypt.org/) certificate for new domain and update it via [certbot](https://certbot.eff.org/docs/using.html).
- Support random custom error pages.

## Thanks

- [nginxinc/docker-nginx](https://github.com/nginxinc/docker-nginx)
- [sebble/docker-images/letsencrypt-certbot](https://github.com/sebble/docker-images/tree/master/letsencrypt-certbot)
- [nrollr/nginx.conf](https://gist.github.com/nrollr/9a39bb636a820fb97eec2ed85e473d38)
- [JrCs/docker-letsencrypt-nginx-proxy-companion](https://github.com/JrCs/docker-letsencrypt-nginx-proxy-companion)
- [tmthrgd/nginx-status-text.conf](https://gist.github.com/tmthrgd/3504859568e1dba9ee80e260f974a708): Nginx status code to message map.
- [Using NGINX’s X-Accel with Remote URLs](https://www.mediasuite.co.nz/blog/proxying-s3-downloads-nginx/)
- [How to make an existing caching Nginx proxy use another proxy to bypass a firewall?](https://serverfault.com/questions/583743/how-to-make-an-existing-caching-nginx-proxy-use-another-proxy-to-bypass-a-firewa#683955)

## Reference

- [Nginx ssl_stapling](http://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_stapling)
- [Nginx alias](http://nginx.org/en/docs/http/ngx_http_core_module.html#alias): Used to change the directory path of the request file.
- [Nginx sub_filter](http://nginx.org/en/docs/http/ngx_http_sub_module.html#sub_filter): Filter and modify the response body.
- [Nginx error_page](http://nginx.org/en/docs/http/ngx_http_core_module.html#error_page): Define the error page or URI.
- [Nginx random_index](http://nginx.org/en/docs/http/ngx_http_random_index_module.html#random_index): Picks a random file in a directory to serve as an index file.
- [Nginx proxy_intercept_errors](http://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_intercept_errors): Intercept proxy errors and redirected them to nginx for processing with the `error_page` directive.
- [Nginx proxy_hide_header](http://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_hide_header): Hide the headers from the response of a proxied server to a client.
- [Nginx variables](http://nginx.org/en/docs/varindex.html)
