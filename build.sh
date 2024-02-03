#!/bin/bash

#docker build -t haas .
docker build -t mikromcz/haas --label "org.opencontainers.image.version=2.0.2" --label "org.opencontainers.image.created=$(date +'%F')" .
