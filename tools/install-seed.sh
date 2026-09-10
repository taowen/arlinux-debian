#!/bin/sh
set -eu

# Runs inside the pinned ARM64 Debian build container. apt/dpkg define the
# filesystem; this is not an ELF copier.
debian_sources="${BIONICX_DEBIAN_SOURCES:?missing BIONICX_DEBIAN_SOURCES}"
mkdir -p /etc/apt/sources.list.d
cp "$debian_sources" /etc/apt/sources.list.d/debian.sources
# The minimal OCI image has no CA bundle yet. apt still verifies the signed
# repository metadata during this one bootstrap transaction.
if [ ! -s /etc/ssl/certs/ca-certificates.crt ]; then
    sed -i 's|https://|http://|g' /etc/apt/sources.list.d/debian.sources
fi

export DEBIAN_FRONTEND=noninteractive
printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d
chmod 0755 /usr/sbin/policy-rc.d
mkdir -p /var/cache/apt/archives/partial

apt-get -o Acquire::http::Pipeline-Depth=0 \
    -o Acquire::http::No-Cache=true update
# Host image is only the package-manager/runtime seed. Applications and desktop
# services are installed on device by apt from the same mirror.
apt-get -o Acquire::http::Pipeline-Depth=0 \
    -o Acquire::http::No-Cache=true install -y --no-install-recommends \
    apt binutils ca-certificates coreutils curl dash debian-archive-keyring dpkg \
    findutils grep patchelf sed systemd-standalone-sysusers
cp "$debian_sources" /etc/apt/sources.list.d/debian.sources
dpkg --audit

mkdir -p /ardesk/metadata
apt-mark showmanual | sort > /ardesk/metadata/manual-packages.txt
dpkg-query -W -f='${binary:Package}\t${Version}\n' | sort \
    > /ardesk/metadata/packages.tsv

apt-get clean
rm -rf /var/lib/apt/lists/* /var/log/* /tmp/* /var/tmp/*
: > /etc/machine-id
