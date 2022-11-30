#!/bin/bash
set -e

ZEPTO_VER=$(cat src/VERSION | tr -s '\n')
KERNEL_VER=$(cat src/KERNEL | tr -s '\n')

#wget -q --show-progress https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-"$KERNEL_VER".tar.xz -O linux.tar.xz

echo "Zepto Linux - v$ZEPTO_VER for Linux kernel v$KERNEL_VER"

DOCKER_BUILDKIT=1 docker build --build-arg ZEPTO_VER=${ZEPTO_VER} --build-arg KERNEL_VER=${KERNEL_VER} -t zeptolinux-builder:${KERNEL_VER}-zepto${ZEPTO_VER} -o build/ .
