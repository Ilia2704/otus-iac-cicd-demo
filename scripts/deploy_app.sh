#!/usr/bin/env sh
set -eu

IMAGE_TAR=${1:-/tmp/sentiment-api.tar.gz}
APP_IMAGE=${2:-sentiment-api:ci}

gunzip -c "$IMAGE_TAR" | docker load

docker network create ai-demo 2>/dev/null || true

docker rm -f sentiment-api 2>/dev/null || true

docker run -d \
  --name sentiment-api \
  --restart unless-stopped \
  --network ai-demo \
  -p 8000:8000 \
  -e OLLAMA_URL=http://ollama:11434 \
  "$APP_IMAGE"
