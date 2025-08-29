#!/bin/bash

TITLE="SpamAssassin"
DESCRIPTION="Spam filter for email which can be invoked from mail delivery agents"
MAINTAINER=""
WEBSITE="https://spamassassin.apache.org/"
SOURCE="https://github.com/Olen/spamassassin-docker/"

PUID=$(id -u)
PGID=$(id -g)

CONTAINER_REGISTRY="git.olen.net/olen"

if [ -z "$TITLE" ]; then
    echo "You need to add at least a title"
    exit 1
fi

pre_build() {
    # Any commands that must run before the build starts
    :
}

get_new_version() {
    # Get the version number of the latest version of the app
    local ver
    ver=$(curl --silent https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/x86_64/APKINDEX.tar.gz | zcat | awk -F: '/^P:/ {pkg=$2} /^V:/ {if (pkg=="spamassassin") {print $2; exit}}')
    printf '%s\n' "$ver"
}


safe_docker_name() {
    # Create a valid container/image name
    local name="$*"
    name=${name,,}                                      # lowercase
    name=$(printf '%s' "$name" | tr -c 'a-z0-9._-' '-') # non-allowed -> '-'
    name=$(printf '%s' "$name" | sed -E 's/[-]+/-/g')   # collapse to single '-'
    name=$(printf '%s' "$name" | sed -E 's/[_]+/_/g')   # collapse to single '_'
    name=$(printf '%s' "$name" | sed -E 's/[.]+/./g')   # collapse to single '.'
    name=$(remove_all_trails $name)
    if [[ -z $name ]]; then
        echo "❌ Unable to create valid image name."
        exit 1
    fi
    printf '%.128s\n' "$name"
}

remove_all_trails() {
    # Recursively remove all leading and trailing separators
    local in="$*"
    local out="$*"
    out=${out#-}; out=${out%-}                            # trim leading/trailing '-'
    out=${out#.}; out=${out%.}                            # trim leading/trailing '.'
    out=${out#_}; out=${out%_}                            # trim leading/trailing '_'
    if [[ "$in" == "$out" ]]; then
        printf '%s\n' "$out"
    else
        printf '%s\n' $(remove_all_trails $out)
    fi  
}

get_docker_label() {
    # Get the value of a container label
    local val
    val=$(docker inspect $1 | jq -r '.[]["Config"]["Labels"]["'$2'"]')
    printf '%s\n' "$val"
}

IMAGE_NAME=$(safe_docker_name "$TITLE")
CONTAINER_NAME="$IMAGE_NAME"
BUILD_DATE=$(date --iso-8601=seconds)
RUN_VERSION=$(get_docker_label "${CONTAINER_NAME}" "org.opencontainers.image.version")
NEW_VERSION=$(get_new_version "${CONTAINER_NAME}")

echo "🐳 Starting build of ${CONTAINER_NAME}"

pre_build "${CONTAINER_NAME}"

echo "📦 Current running version: ${RUN_VERSION}"

if [ -z $NEW_VERSION ]; then
    echo "❌ No new version defined."
    exit 1
fi
echo "📦 New version: ${NEW_VERSION}"

if [ "$RUN_VERSION" == "$NEW_VERSION" ]; then
    echo "✅ Already running the latest version. No action needed."
    exit 0
else
    echo "🚀 Building new Docker image for ${TITLE} (${CONTAINER_NAME}) version ${NEW_VERSION}..."
fi

docker build -t "${IMAGE_NAME}:latest" \
        --build-arg DATE="${BUILD_DATE}" \
        --build-arg DESCRIPTION="${DESCRIPTION}" \
        --build-arg MAINTAINER="${MAINTAINER}" \
        --build-arg NAME="${IMAGE_NAME}" \
        --build-arg SOURCE="${SOURCE}" \
        --build-arg TITLE="${TITLE}" \
        --build-arg VERSION="${NEW_VERSION}" \
        --build-arg WEBSITE="${WEBSITE}" \
        --build-arg UID="${PUID}" \
        --build-arg GID="${PGID}" \
        .

docker tag "${IMAGE_NAME}" "${IMAGE_NAME}:${NEW_VERSION}"
docker tag "${IMAGE_NAME}" "${CONTAINER_REGISTRY}/${IMAGE_NAME}"
docker tag "${IMAGE_NAME}" "${CONTAINER_REGISTRY}/${IMAGE_NAME}:${NEW_VERSION}"
docker push "${CONTAINER_REGISTRY}/${IMAGE_NAME}"
docker push "${CONTAINER_REGISTRY}/${IMAGE_NAME}:${NEW_VERSION}"

echo "🐳 Launch new version with: docker compose -f /home/docker/docker-compose.yaml up -d ${CONTAINER_NAME}"
