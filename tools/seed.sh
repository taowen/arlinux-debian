#!/usr/bin/env bash
set -euo pipefail
product="$(cd "$(dirname "$0")/.." && pwd)"
out="${1:?rootfs output required}"
base_image="docker.io/library/debian@sha256:c94f5ddd41327aa2d4a7cfba7889056c02936182fd76a513fec6160c97181fc0"
input_id="$(sha256sum "$product/tools/install-seed.sh" "$product/guest/debian.sources" | sha256sum | cut -c1-20)"
image="localhost/arlinux-debian-seed:$input_id"
container="arlinux-debian-seed-$$"
trap 'podman rm -f "$container" >/dev/null 2>&1 || true' EXIT
if ! podman image exists "$image"; then
    podman create --name "$container" --arch arm64 --network host \
        --env BIONICX_DEBIAN_SOURCES=/tmp/debian.sources \
        --env http_proxy= --env https_proxy= --env HTTP_PROXY= --env HTTPS_PROXY= \
        "$base_image" /bin/sh /tmp/install-seed.sh >/dev/null
    podman cp "$product/tools/install-seed.sh" "$container:/tmp/install-seed.sh"
    podman cp "$product/guest/debian.sources" "$container:/tmp/debian.sources"
    podman start --attach "$container"
    podman commit "$container" "$image" >/dev/null
    podman rm "$container" >/dev/null
fi
podman create --name "$container" --arch arm64 "$image" /bin/true >/dev/null
mkdir -p "$out"
podman export "$container" | tar --no-same-owner --exclude=./dev --exclude=./proc --exclude=./sys -xf - -C "$out"
