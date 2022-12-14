#!/bin/bash
set -ev

if [ -z "$VERSION" ]; then
  echo "VERSION must be set."
  exit 1
fi

if [ -z "$WORKSPACE" ]; then
  echo "WORKSPACE must be set."
  exit 1
fi
cd $WORKSPACE
if [ ! -e "AppRun" ]; then
  echo "You must be in the same directory where the AppRun file resides"
  exit 1
fi

MINISIGN_VERSION="0.10"
TOOLS_DIR="/tools"
MINISIGN_PATH="$TOOLS_DIR/minisign-$MINISIGN_VERSION-linux/x86_64/minisign"
URI=https://releases.wildfiregames.com

# 0ad signing keys
# key for a26
MINISIGN_KEY=RWTWLbO12+ig3lUExIor3xd6DdZaYFEozn8Bu8nIzY3ImuRYQszIQyyy
# key for a25
# MINISIGN_KEY=RWT0hFWv57I2RFoJwLVjxEr44JOq/RkEx1oT0IA3PPPICnSF7HFKW1CT

linux_deploy_version="1-alpha-20220822-1"

mkdir -m 777 -p $TOOLS_DIR
cd "$TOOLS_DIR"

if [ ! -r "linuxdeploy-$ARCH.AppImage" ]; then
  curl -LO https://github.com/linuxdeploy/linuxdeploy/releases/download/$linux_deploy_version/linuxdeploy-$ARCH.AppImage
  chmod +x linuxdeploy-$ARCH.AppImage
  ./linuxdeploy-$ARCH.AppImage --appimage-extract
fi

if [ ! -r minisign-${MINISIGN_VERSION}-linux.tar.gz ]; then
  curl -LO https://github.com/jedisct1/minisign/releases/download/${MINISIGN_VERSION}/minisign-${MINISIGN_VERSION}-linux.tar.gz
  curl -LO https://github.com/jedisct1/minisign/releases/download/${MINISIGN_VERSION}/minisign-${MINISIGN_VERSION}-linux.tar.gz.minisig
fi
tar xf minisign-$MINISIGN_VERSION-linux.tar.gz
$MINISIGN_PATH -Vm minisign-$MINISIGN_VERSION-linux.tar.gz -P RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3

cd "$WORKSPACE"

# The gtk plugin is placed in this directory because this is where linuxdeploy
# is run from later to create the AppImage. In this location, the plugin will
# be visible to linuxdeploy when the AppImage is created
if [ ! -r linuxdeploy-plugin-gtk.sh ]; then
  curl -LO https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gtk/master/linuxdeploy-plugin-gtk.sh
  chmod +x linuxdeploy-plugin-gtk.sh
fi

# Get, check, and extract source
source=0ad-$VERSION-unix-build.tar.xz
source_sum=$source.sha1sum

for file in $source $source_sum; do
  if [ ! -r "$file" ]; then
    curl -LO "$URI/$file"
  fi
done

if [ -n "${URI##*/rc*}" ]; then
  if [ ! -r $URI/$source.minisig ]; then
    curl -LO $URI/$source.minisig
  fi
  $MINISIGN_PATH -Vm $source -P $MINISIGN_KEY
fi
sha1sum -c $source_sum

BUILD_DIR="/build"
mkdir -m 777 -p $BUILD_DIR
cd $BUILD_DIR
su 0ad --command "tar xJf $WORKSPACE/$source"

# name: build
cd 0ad-$VERSION/build/workspaces
su 0ad --command "./update-workspaces.sh \
  -j$(nproc) && \
  make config=release -C gcc -j$(nproc)"

# name: prepare AppDir
cd $WORKSPACE
# Get, check, and extract data
data=0ad-$VERSION-unix-data.tar.xz
data_sum=$data.sha1sum
echo "Getting data and extracting archive..."
for file in $data $data_sum; do
  if [ ! -r "$file" ]; then
    curl -LO "$URI/$file"
  fi
done

if [ -n "${URI##*/rc*}" ] && [ ! -r $URI/$data.minisig ]; then
    curl -LO $URI/$data.minisig
fi

$MINISIGN_PATH -Vm $data -P $MINISIGN_KEY
sha1sum -c $data_sum
su 0ad --command "tar xJf $data -C $BUILD_DIR"

ABS_PATH_SRC_ROOT="$BUILD_DIR/0ad-$VERSION"
if [ ! -r "$ABS_PATH_SRC_ROOT/source/main.cpp" ]; then
  echo "set the source root!"
  exit 1
fi

APPDIR="$BUILD_DIR/AppDir"
cd $ABS_PATH_SRC_ROOT
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
  patchelf --set-rpath $lib:$ABS_PATH_SRC_ROOT/binaries/system pyrogenesis
done
patchelf --set-rpath libthai.so.0:$APPDIR/usr/lib ActorEditor
patchelf --set-rpath libAtlasUI.so:$ABS_PATH_SRC_ROOT/binaries/system ActorEditor
# Note that binaries/system{libmoz*.so, libnv*.so, libAtlasUI.so} will be copied into
# the $APPDIR folder automatically when linuxdeploy is run below.
cd $ABS_PATH_SRC_ROOT
install binaries/system/libCollada.so -Dt $APPDIR/usr/lib
install build/resources/0ad.appdata.xml -Dt $APPDIR/usr/share/metainfo
install build/resources/0ad.desktop -Dt $APPDIR/usr/share/applications
install build/resources/0ad.png -Dt $APPDIR/usr/share/pixmaps
mkdir -p "$APPDIR/usr/data/config"
cp -a binaries/data/config/default.cfg $APPDIR/usr/data/config
cp -a binaries/data/l10n $APPDIR/usr/data
cp -a binaries/data/tools $APPDIR/usr/data # for Atlas
cp -a binaries/data/mods $APPDIR/usr/data
# Create the image
cd "$WORKSPACE"

DEPLOY_GTK_VERSION=3 # Variable used by gtk plugin
$TOOLS_DIR/squashfs-root/AppRun -d $APPDIR/usr/share/applications/0ad.desktop \
  --icon-file=$APPDIR/usr/share/pixmaps/0ad.png \
  --icon-filename=0ad \
  --executable $APPDIR/usr/bin/pyrogenesis \
  --library=/usr/lib/x86_64-linux-gnu/libthai.so.0 \
  --custom-apprun=$WORKSPACE/AppRun \
  --appdir $APPDIR \
  --output appimage \
  --plugin gtk
DATE_STR=$(date +%y%m%d%H%M)
mv 0_A.D.-$VERSION-$ARCH.AppImage 0ad-$VERSION-$DATE_STR-$ARCH.AppImage
echo "Generating sha1sum..."
sha1sum 0ad-$VERSION-$DATE_STR-$ARCH.AppImage > 0ad-$VERSION-$DATE_STR-$ARCH.AppImage.sha1sum

if [ -n "$HOSTUSER" ]; then
  for file in 0ad*AppImage 0ad*.xz 0ad*.minisig  0ad*.sha1sum linuxdeploy-plugin-gtk.sh; do
    chown $HOSTUSER "$file"
  done
fi

exit 0
