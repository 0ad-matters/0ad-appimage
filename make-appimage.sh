#!/bin/sh

export WORKSPACE="/0ad"

docker run -it --rm \
  -e VERSION=$(cat version)  \
  -e ARCH=x86_64 \
  -e WORKSPACE \
  -e HOSTUSER=$USER \
  -v $PWD:$WORKSPACE \
  --entrypoint /0ad/workflow.sh \
  andy5995/0ad-build-env:bionic
