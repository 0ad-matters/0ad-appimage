#!/bin/sh

export WORKSPACE="/0ad"

docker run -it --rm \
  -e VERSION=0.0.26-alpha  \
  -e NAME=0ad \
  -e ARCH=x86_64 \
  -e WORKSPACE \
  -v $PWD:$WORKSPACE \
  0ad-build-appimage
