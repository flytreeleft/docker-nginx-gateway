Nginx Gateway
===============================

A tiny, flexable, configurable Nginx gateway (reverse proxy) Docker image based on the [alpine image](https://hub.docker.com/_/alpine/).

## Features

- Enable HTTPS with [Let’s Encrypt](https://letsencrypt.org/).
- Automatically register [Let’s Encrypt](https://letsencrypt.org/) certificate for new domain and update it via [certbot](https://certbot.eff.org/docs/using.html).
- Support random custom error pages.

## Thanks

- [nginxinc/docker-nginx](https://github.com/nginxinc/docker-nginx)
- [sebble/docker-images/letsencrypt-certbot](https://github.com/sebble/docker-images/tree/master/letsencrypt-certbot)
- [nrollr/nginx.conf](https://gist.github.com/nrollr/9a39bb636a820fb97eec2ed85e473d38)
- [JrCs/docker-letsencrypt-nginx-proxy-companion](https://github.com/JrCs/docker-letsencrypt-nginx-proxy-companion)
- [tmthrgd/nginx-status-text.conf](https://gist.github.com/tmthrgd/3504859568e1dba9ee80e260f974a708)

## Reference

- [Nginx ngx_http_sub_module](http://nginx.org/en/docs/http/ngx_http_sub_module.html): Filter and modify the response body.
- [Nginx error_page](http://nginx.org/en/docs/http/ngx_http_core_module.html#error_page): Define the error page or URI.
- [Nginx alias](http://nginx.org/en/docs/http/ngx_http_core_module.html#alias): Used to change the directory path of the request file.
- [Nginx proxy_intercept_errors](http://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_intercept_errors): Intercept proxy errors and redirected them to nginx for processing with the `error_page` directive.
