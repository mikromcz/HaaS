#!/bin/bash

# pull alpine
echo "Pull Alpine Python"
#docker pull python:alpine
docker pull python:3.12-alpine

# build haas
echo "Build HaaS with current date label"
#docker build -t haas .
docker build -t mikromcz/haas --label "org.opencontainers.image.version=2.0.2" --label "org.opencontainers.image.created=$(date +'%F')" .
