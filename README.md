# 0ad appimage

As of release 28, the 0 A.D. project now produces [an official
AppImage](https://play0ad.com/download/linux/), and this repository will be
archived as read-only. The content below should be disregarded and considered
outdated.

Unofficial [0ad](https://play0ad.com/)
[AppImage](https://appimage.org/) (built from official sources and
data)

Click on the [releases
link](https://github.com/0ad-matters/0ad-appimage/releases) to view
available appimages.

To invoke the `ActorEditor`:

    BINARY_NAME=ActorEditor <path/to/AppImage>

## Updating

The AppImage is updateable (if you downloaded it after February 1st, 2025)
with
[appimageupdatetool](https://github.com/AppImageCommunity/AppImageUpdate). If
it's not available from your distro, you can download the tool as an AppImage
from the repo (linked above) or by using [AM, a command line AppImage package
manager](https://github.com/ivan-hc/AM).

## Build locally

You can build the appimage locally if you have docker installed. While in the
repo root, to build the latest stable version:

    export HOSTUID=$(id -u) HOSTGID=$(id -g)
    docker compose -f ./docker-compose.yml  run --rm build
