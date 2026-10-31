#!/bin/bash

# v20261031

# Monthly rebuild to pick up security fixes from base image and packages.
# Build (build.sh) -> push to Docker Hub (push.sh) -> recreate local container.
#
# crontab -e:
# 30 4 1 * * /home/mikrom/docker/haas/rebuild.sh >> /home/mikrom/docker/haas/rebuild.log 2>&1

# Run from the directory of this script (cron starts in $HOME)
cd "$(dirname "$(readlink -f "$0")")" || exit 1

echo "===== $(date +'%F %T'): Rebuild $(basename "$PWD") ====="

# build.sh uses --pull, so the latest base image is always used
if ! ./build.sh; then
    echo "===== $(date +'%F %T'): ERROR - build failed, nothing pushed ====="
    exit 1
fi

if ! ./push.sh; then
    echo "===== $(date +'%F %T'): ERROR - push failed ====="
    exit 1
fi

# Recreate local container with the new image
if ! docker compose up -d; then
    echo "===== $(date +'%F %T'): ERROR - recreating container failed ====="
    exit 1
fi

# Remove old untagged images left over after rebuild
docker image prune -f

echo "===== $(date +'%F %T'): FINISHED OK ====="
