# 0ad appimage

Unofficial [0ad](https://play0ad.com/)
[AppImage](https://appimage.org/) (built from official sources and
data)

Click on the [releases
link](https://github.com/0ad-matters/0ad-appimage/releases) to view
available appimages.

To invoke the `ActorEditor`:

    BINARY_NAME=ActorEditor <path/to/AppImage>

## Build locally

You can build the appimage locally if you have docker installed. While in the
repo root, to build the latest stable version:

    export HOSTUID=$(id -u) HOSTGID=$(id -g) VERSION=0.27.0
    docker compose -f ./docker-compose.yml  run --rm build
