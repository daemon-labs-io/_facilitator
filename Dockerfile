FROM nginx:alpine AS nginx-base

# For nginx targets (proxy, fileserver)
HEALTHCHECK --interval=1s --timeout=1s --retries=30 CMD curl -f http://localhost/ || exit 1

# proxy
FROM nginx-base AS proxy

COPY ./nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./certs/labs /etc/nginx/certs
COPY ./www /usr/share/nginx/html

# fileserver
FROM nginx-base AS fileserver

COPY ./www /usr/share/nginx/html

# registry
FROM registry:2 AS registry

COPY ./registry/config.yml /etc/docker/registry/config.yml

HEALTHCHECK --interval=1s --timeout=1s --retries=30 CMD wget --quiet --tries=1 --spider http://localhost:5000/v2/ || exit 1

FROM joxit/docker-registry-ui:latest AS ui

HEALTHCHECK --interval=1s --timeout=1s --retries=30 CMD wget --quiet --tries=1 --spider http://127.0.0.1/ || exit 1
