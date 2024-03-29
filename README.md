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
repo root, to build the latest stable version, run:

    ./make-appimage.sh

or to build an svn snapshot:

    VERSION=0.0.27-svn-unstable ./make-appimage.sh

Version strings for stable releases are typically in the format:

    0.0.26-alpha
    0.0.25b-alpha
    0.0.27-rc1-xxxxx-alpha (for release candidates)

To build on a different version of Ubuntu, precede the script with the
codename, e.g.

    UBUNTU_CODENAME=jammy ./make_appimage.sh

(valid values are bionic, focal, or jammy)

To speed up the process, prior to running the above script, copy the source
and data archives (e.g., 0ad-0.0.26-alpha-unix-{build,data}.tar.xz) to the
repo root (otherwise they'll be downloaded during the script execution).

If choosing the svn version, the svn repository will be checked out, unless
you aleady have it in the repo root.

## HOWTO change versions after a 0 A.D. release

When running from the GitHub CI, change the VERSION string near the top of
appimage.yml.

If running the `make-appimage.sh` script locally, change the default VERSION
string near the top of `make-appimage.sh`.

In either case, you may also need to change the minisign key near the top of
`workflow.sh`.

To customize and publish the docker image (see the Dockerfile in this repo) to
your own Docker Hub account, you'll need to add a couple secrets to your
repository. See https://docs.github.com/en/actions/publishing-packages/publishing-docker-images


