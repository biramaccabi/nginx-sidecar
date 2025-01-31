#!/bin/sh

set -ex

# nginx.conf doesn't support environment variables,
# so we substitute at run time
/bin/sed \
  -e "s/<NGINX_STATUS_PORT>/${NGINX_STATUS_PORT:-81}/g" \
  -e "s:<NGINX_STATUS_ALLOW_FROM>:${NGINX_STATUS_ALLOW_FROM:-all}:g" \
  -e "s/<NGINX_PORT>/${NGINX_PORT}/g" \
  -e "s/<APP_HOST>/${APP_HOST:-app}/g" \
  -e "s/<APP_PORT>/${APP_PORT}/g" \
  -e "s/<CLIENT_BODY_BUFFER_SIZE>/${CLIENT_BODY_BUFFER_SIZE:-8k}/g" \
  -e "s:<PROXY_TIMEOUT>:${PROXY_TIMEOUT:-60s}:g" \
  /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Wait for the application to start before accepting ALB requests.
while sleep 2; do
  curl --verbose --fail --max-time 5 "http://${APP_HOST:-app}:${APP_PORT}${HEALTHCHECK_PATH:-/health}" && break
done

# run in foreground as pid 1
exec /usr/sbin/nginx -g 'daemon off;' -c /etc/nginx/nginx.conf
