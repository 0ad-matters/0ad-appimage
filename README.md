# 0ad appimage

Unofficial [0ad](https://play0ad.com/)
[AppImage](https://appimage.org/) (built from official sources and
data)

Click on the [releases
link](https://github.com/0ad-matters/0ad-appimage/releases) to view
available appimages.

To access the `ActorEditor`, you'll need to create a [symbolic
link](https://devdojo.com/devdojo/what-is-a-symlink):

    cd /path/to/<Appimage-File>
    ln -s <Appimage-File> ActorEditor

You can optionally create symbolic links for `0ad` and `pyrogenesis`
if desired:

    ln -s <Appimage-File> 0ad
    ln -s <Appimage-File> pyrogenesis

## Build locally

You can build the appimage locally if you have docker installed. While in the
repo root, to build the latest stable version, see the docker run arguments in
.github/workflows/appimage.yml (note you'll have to change variables that
normally get created earlier in the yml file).

Version strings for stable releases are typically in the format:

    0.0.26-alpha
    0.0.25b-alpha
    0.0.27-rc1-xxxxx-alpha (for release candidates)

To build on a different version of Ubuntu, precede the script with the
codename, e.g.

    UBUNTU_CODENAME=jammy ./make_appimage.sh

(valid values are focal, or jammy)
