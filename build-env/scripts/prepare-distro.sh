#!/bin/bash

set -e

# Much of the following are taken from the ct-ng test suite:
# https://github.com/crosstool-ng/crosstool-ng/blob/cf6b1740a14634406bb3426309dd92af8faa06fb/testing/docker/ubuntu22.04/Dockerfile

groupadd -g "$BUILDER_GID" b
useradd -d /home/b -m -g "$BUILDER_GID" -u "$BUILDER_UID" -s /bin/bash b

export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

# HTTPS needs ca-certificates to work
sed -i 's@http://archive\.ubuntu\.com/@http://mirrors.huaweicloud.com/@g' /etc/apt/sources.list

# For `apt build-dep`
sed -i 's/^# deb-src/deb-src/' /etc/apt/sources.list

# Non-interactive configuration of tzdata
debconf-set-selections <<EOF
tzdata tzdata/Areas select Etc
tzdata tzdata/Zones/Etc select UTC
EOF

apt-get update

# Install recent cmake
apt-get install -y wget software-properties-common lsb-release ca-certificates
wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null
apt-add-repository "deb https://apt.kitware.com/ubuntu/ $(lsb_release -cs) main"

# And recent LLVM
wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc
apt-add-repository "deb http://apt.llvm.org/focal/ llvm-toolchain-focal-17 main"

apt-get update

pkgs=(
    # for ct-ng
    gcc g++ gperf bison flex texinfo help2man make libncurses5-dev
    python3-dev autoconf automake libtool libtool-bin gawk bzip2 xz-utils unzip
    patch libstdc++6 rsync git meson ninja-build

    # for targetting riscv64 host
    g++-riscv64-linux-gnu

    # for targetting aarch64 host
    g++-aarch64-linux-gnu

    # for ruyi-build driver
    schedtool

    # common goodies
    zstd libzstd-dev clang-17 lld-17

    # for LLVM
    build-essential cmake pkgconf
    libedit-dev libffi-dev libjsoncpp-dev libz3-dev liblzma-dev

    # for QEMU
    python3-venv
)

apt-get upgrade -qqy
apt-get install -y "${pkgs[@]}"

# for QEMU
apt-get build-dep -y qemu

apt-get clean
