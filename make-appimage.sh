#!/bin/sh



export WORKSPACE="/0ad"
export VERSION=${VERSION:="0.0.26-alpha"}

echo "Version is set to '$VERSION'"
echo "use 'VERSION=<version> $0' to change it."
echo "Waiting 10 seconds to start, hit CTRL-C now to cancel..."

read -t 10

set -ev

docker run -it --rm \
  -u 0ad \
  -e VERSION=$VERSION  \
  -e ARCH=x86_64 \
  -e WORKSPACE \
  -e HOSTUSER=$USER \
  -v $PWD:$WORKSPACE \
  --entrypoint /0ad/workflow.sh \
  andy5995/0ad-build-env:bionic
