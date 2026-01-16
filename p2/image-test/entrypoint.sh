#!/bin/sh

envsubst < /index.html.template > /usr/share/nginx/html/index.html

exec nginx -g "daemon off;"
