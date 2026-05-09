#!/bin/bash

# v202600509

# build haas
echo "Build HaaS with current date label"

# --pull forces pulling the latest base image
# Command without BuildKit - shows warning about deprecated features - see below
docker build --pull -t mikromcz/haas --label "org.opencontainers.image.version=2.0.2" --label "org.opencontainers.image.created=$(date +'%F')" .

## BuildKit
# For buildx, first "sudo apt-get install docker-buildx-plugin" is needed

# Using BuildKit to avoid warnings about deprecated features does not work with older Docker versions
#docker buildx build -t mikromcz/pqget --label "org.opencontainers.image.created=$(date +'%F')" .

# Using BuildKit to avoid warnings about deprecated features
#DOCKER_BUILDKIT=1 docker build -t mikromcz/pqget --label "org.opencontainers.image.created=$(date +'%F')" .
