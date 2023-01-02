#!/bin/sh

export WORKSPACE="/0ad"

docker run -it --rm \
  -e VERSION=0.0.26-alpha  \
  -e ARCH=x86_64 \
  -e WORKSPACE \
  -v $PWD:$WORKSPACE \
  --entrypoint /0ad/workflow.sh \
  andy5995/0ad-build-env:bionic
