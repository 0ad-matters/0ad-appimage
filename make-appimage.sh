#!/bin/sh

export VERSION=0.0.26-alpha
export NAME=0ad
export URI=https://releases.wildfiregames.com
export ARCH=x86_64
export MINISIGN_VERSION="0.10"
export WORKSPACE="/0ad"
#export MINISIGN_PATH="/build/minisign-$MINISIGN_VERSION-linux/x86_64/minisign"

docker run -it --rm \
  -e VERSION  \
  -e NAME \
  -e URI \
  -e ARCH \
  -e WORKSPACE \
  -e MINISIGN_VERSION \
  -e MINISIGN_PATH="/tools/minisign-$MINISIGN_VERSION-linux/x86_64/minisign"  \
  -v $PWD:$WORKSPACE \
  0ad-build-appimage
