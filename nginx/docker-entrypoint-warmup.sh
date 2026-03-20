#!/bin/sh
# Warm filesystem cache by reading all served files into memory
find /usr/share/nginx/html -type f -exec cat {} + > /dev/null 2>&1

# Hand off to the default nginx entrypoint
exec /docker-entrypoint.sh "$@"
