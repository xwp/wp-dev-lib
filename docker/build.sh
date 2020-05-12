#!/bin/bash

IMAGE_NAME="xwpco/wp-dev-lib"
IMAGE_SRC_DIR="$(dirname "$0")/wp-dev-lib"

REPO_TAG=$(git describe --tags $(git rev-list --tags --max-count=1))
WP_DEV_LIB_VERSION=${WP_DEV_LIB_VERSION:-$REPO_TAG}

# Don't provide the "latest" tag to ensure users always lock to a specific version.
docker build \
	--build-arg WP_PHP_VERSION=7.4 \
	--tag "$IMAGE_NAME:$WP_DEV_LIB_VERSION" \
	--tag "$IMAGE_NAME:$WP_DEV_LIB_VERSION-php7.4" \
	"$IMAGE_SRC_DIR"

