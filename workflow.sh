#!/bin/bash

cmp_substr () {
  if [ -z "$1" -o -z "$2" ]; then
    return 1
  fi
  [ -z "${1##*$2*}" ]
  return $?
}

set -ev

WORKSPACE=${WORKSPACE:-$ACTION_WORKSPACE}
WORKSPACE=${WORKSPACE:-$(pwd)}
if [[ "$WORKSPACE" != /* ]]; then
  echo "The workspace path must be absolute"
  exit 1
fi
test -d "$WORKSPACE"

SOURCE_ROOT=${SOURCE_ROOT:-$ACTION_SOURCE_ROOT}
SOURCE_ROOT=${SOURCE_ROOT:-$WORKSPACE}
if [[ "$SOURCE_ROOT" != /* ]]; then
  echo "The source root path must be absolute"
  exit 1
fi

if [ ! -r "$SOURCE_ROOT/source/main.cpp" ]; then
  echo "set the source root!"
  exit 1
fi

APPDIR=${APPDIR:-"/tmp/$USER-AppDir"}
if [ -d "$APPDIR" ]; then
  rm -rf "$APPDIR"
else
  mkdir -v -p "$APPDIR"
fi

env
export -p

URI=https://releases.wildfiregames.com/rc

cd $WORKSPACE
if [ ! -e "AppRun" ]; then
  echo "You must be in the same directory where the AppRun file resides"
  exit 1
fi

cd "$WORKSPACE"

#!/bin/bash

# Set DEBIAN_FRONTEND to noninteractive
export DEBIAN_FRONTEND=noninteractive
# Pre-configure debconf selections to avoid prompts
echo "keyboard-configuration  keyboard-configuration/layoutcode  string  us" | sudo debconf-set-selections
sudo apt update && sudo apt -y upgrade && \
  sudo apt install -y  \
    cargo   \
    libboost-dev    \
    g++-8 \
    libboost-filesystem-dev \
    libboost-system-dev   \
    libcurl4-gnutls-dev \
    libenet-dev \
    libfmt-dev   \
    libfreetype6-dev    \
    libgloox-dev    \
    libicu-dev \
    libminiupnpc-dev \
    libogg-dev  \
    libopenal-dev   \
    libpng-dev  \
    libsdl2-dev \
    libsodium-dev   \
    libvorbis-dev \
    libvulkan-dev   \
    libwxgtk3.0-gtk3-dev \
    libxml2-dev \
    m4 \
    python3 \
    rustc   \
    zlib1g-dev

# needed for spidermonkey build
export SHELL=/bin/bash
# Spidermonkey build fails with 7, 8, 9, and 10 on Ubuntu focal?
export CC=gcc-7
export CXX=g++-7
# Using some Debian patches might work
# https://packages.debian.org/bookworm/0ad
# Giving up for now... -andy5995/2024-02-09
cd "$SOURCE_ROOT/build/workspaces"

/bin/bash -c './update-workspaces.sh \
    -j$(nproc) && \
  make config=release -C gcc -j$(nproc)'

# name: prepare AppDir
cd $WORKSPACE
  #if [ -n "${URI##*/rc*}" ] && [ ! -r $URI/$data.minisig ]; then
      #curl -LO $URI/$data.minisig
  #fi

  #$MINISIGN_PATH -Vm $data -P $MINISIGN_KEY

cd "$SOURCE_ROOT"
install -s binaries/system/pyrogenesis -Dt $APPDIR/usr/bin
install -s binaries/system/ActorEditor -Dt $APPDIR/usr/bin
cd $APPDIR/usr/bin
ln -s pyrogenesis 0ad
for lib in libmozjs78-ps-release.so \
  libnvcore.so    \
  libnvimage.so   \
  libnvmath.so    \
  libnvtt.so
do
  patchelf --set-rpath $lib:$SOURCE_ROOT/binaries/system pyrogenesis
done
patchelf --set-rpath libthai.so.0:$APPDIR/usr/lib ActorEditor
patchelf --set-rpath libAtlasUI.so:$SOURCE_ROOT/binaries/system ActorEditor
# Note that binaries/system{libmoz*.so, libnv*.so, libAtlasUI.so} will be copied into
# the $APPDIR folder automatically when linuxdeploy is run below.
cd $SOURCE_ROOT
install binaries/system/libCollada.so -Dt $APPDIR/usr/lib
install build/resources/0ad.appdata.xml -Dt $APPDIR/usr/share/metainfo
install build/resources/0ad.png -Dt $APPDIR/usr/share/pixmaps
mkdir -p "$APPDIR/usr/data/config"
cp -a binaries/data/config/default.cfg $APPDIR/usr/data/config
cp -a binaries/data/l10n $APPDIR/usr/data
cp -a binaries/data/tools $APPDIR/usr/data # for Atlas
mkdir -p $APPDIR/usr/data/mods
cp -a binaries/data/mods/mod $APPDIR/usr/data/mods

# Hopefully prevent out-of-space failure when running on a GitHub hosted runner
if [ -n "$ACTION_WORKSPACE" ]; then
  cd "$SOURCE_ROOT/build/workspaces"
  ./clean-workspaces.sh
fi

cd $SOURCE_ROOT
cp -a binaries/data/mods/public $APPDIR/usr/data/mods

## spirv. See https://wildfiregames.com/forum/topic/104382-vulkan-new-graphics-api/
#mkdir $APPDIR/usr/data/mods/0ad-spirv
#cd $APPDIR/usr/data/mods/0ad-spirv
#curl -LO https://releases.wildfiregames.com/rc/0ad-spirv.zip
#curl -LO https://releases.wildfiregames.com/rc/0ad-spirv.zip.sha1sum
#sha1sum -c 0ad-spirv.zip.sha1sum
#rm 0ad-spirv.zip.sha1sum
#unzip 0ad-spirv.zip mod.json

cd "$WORKSPACE"

# Hopefully prevent out-of-space failure when running on a GitHub hosted runner
echo "Removing data from source tree (already copied to ${APPDIR})..."
if [ -n "$ACTION_WORKSPACE" ]; then
  rm -rf "$SOURCE_ROOT/binaries/data"
fi

# Create the image
if [ -z "ACTION_WORKSPACE" ]; then
  export DEPLOY_GTK_VERSION=3 # Variable used by gtk plugin
  linuxdeploy \
    -d $SOURCE_DIR/build/resources/0ad.desktop \
    --icon-file=$SOURCE_DIR/build/resources/0ad.png \
    --icon-filename=0ad \
    --executable $APPDIR/usr/bin/pyrogenesis \
    --library=/usr/lib/x86_64-linux-gnu/libthai.so.0 \
    --custom-apprun=$ACTION_WORKSPACE/AppRun \
    --appdir $APPDIR \
    --output appimage \
    --plugin gtk
fi

#DATE_STR=$(date +%y%m%d%H%M)
#OUT_APPIMAGE="0ad-$VERSION-$DATE_STR-$UBUNTU_CODENAME-$ARCH.AppImage"
#mv 0_A.D.-$VERSION-$ARCH.AppImage $OUT_APPIMAGE
#echo "Generating sha1sum..."
#sha1sum $OUT_APPIMAGE > "$OUT_APPIMAGE.sha1sum"
#cat "$OUT_APPIMAGE.sha1sum"

exit 0
