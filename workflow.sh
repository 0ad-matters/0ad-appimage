#!/bin/bash

cmp_substr () {
  if [ -z "$1" -o -z "$2" ]; then
    return 1
  fi
  [ -z "${1##*$2*}" ]
  return $?
}

set -ev

export {CC=gcc-8,CXX=g++-8}

# This var is set in the the docker container
if [ -z "DOCKER_0AD_BUILD" ]; then
  @echo "This script is intended to be run inside a docker container."
  @echo "(hint: andy5995/0ad-build-env:bionic)"
  exit 1
fi

if [ -z "$VERSION" ]; then
  echo "VERSION must be set."
  exit 1
fi

svn=1
cmp_substr "$VERSION" "svn" || svn=0

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

if [ -z "$TOOLS_DIR" ];
  then TOOLS_DIR="/tools"
fi

if [ ! -d "$TOOLS_DIR" ]; then
  mkdir -v -p "$TOOLS_DIR"
fi

MINISIGN_PATH="$TOOLS_DIR/minisign-$MINISIGN_VERSION-linux/x86_64/minisign"
URI=https://releases.wildfiregames.com

BUILD_DIR="$WORKSPACE/build"
if [ -d "$BUILD_DIR" ]; then
  rm -rf "$BUILD_DIR"
fi
mkdir -v -p $BUILD_DIR

if [ $svn -ne 1 ]; then
  ABS_PATH_SRC_ROOT="$WORKSPACE/0ad-$VERSION"
else
  ABS_PATH_SRC_ROOT="$WORKSPACE/0ad-svn"
fi

echo $ABS_PATH_SRC_ROOT
exit 0

export -p

# 0ad signing keys
# key for a26
MINISIGN_KEY=RWTWLbO12+ig3lUExIor3xd6DdZaYFEozn8Bu8nIzY3ImuRYQszIQyyy
# key for a25
# MINISIGN_KEY=RWT0hFWv57I2RFoJwLVjxEr44JOq/RkEx1oT0IA3PPPICnSF7HFKW1CT

if [ ! -r minisign-${MINISIGN_VERSION}-linux.tar.gz ]; then
  curl -LO https://github.com/jedisct1/minisign/releases/download/${MINISIGN_VERSION}/minisign-${MINISIGN_VERSION}-linux.tar.gz
  curl -LO https://github.com/jedisct1/minisign/releases/download/${MINISIGN_VERSION}/minisign-${MINISIGN_VERSION}-linux.tar.gz.minisig
fi
tar xf minisign-$MINISIGN_VERSION-linux.tar.gz -C "$TOOLS_DIR"
$MINISIGN_PATH -Vm minisign-$MINISIGN_VERSION-linux.tar.gz -P RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3

cd "$WORKSPACE"

# The gtk plugin is placed in this directory because this is where linuxdeploy
# is run from later to create the AppImage. In this location, the plugin will
# be visible to linuxdeploy when the AppImage is created
if [ ! -r linuxdeploy-plugin-gtk.sh ]; then
  curl -LO https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gtk/master/linuxdeploy-plugin-gtk.sh
  chmod +x linuxdeploy-plugin-gtk.sh
fi

if [ "$USER" != "0ad" -]; then
  run_cmd="su 0ad --command"
else
  run_cmd="/bin/bash -c"
fi

if [ $svn -ne 1 ]; then
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
  $run_cmd "tar xJf $WORKSPACE/$source"
else
  if [ ! -r "0ad-svn" ]; then
    svn co https://svn.wildfiregames.com/public/ps/trunk/ 0ad-svn
  else
    cd 0ad-svn
    svn up
    VERSION="$VERSION-r$(svn info --show-item revision)"
  fi
fi

# name: build
if [ ! -r "$ABS_PATH_SRC_ROOT/source/main.cpp" ]; then
  echo "set the source root!"
  exit 1
fi
cd "$ABS_PATH_SRC_ROOT/build/workspaces"

$run_cmd "ionice -c3 nice -n 19 \
  ./update-workspaces.sh \
    -j$(nproc) && \
  make config=release -C gcc -j$(nproc)"

# name: prepare AppDir
cd $WORKSPACE
if [ $svn -ne 1 ]; then
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
  $run_cmd "tar xJf $data"
else
  if [ ! -r 0ad-spirv.zip ]; then
    # see https://wildfiregames.com/forum/topic/104382-vulkan-new-graphics-api/
    curl -LO https://releases.wildfiregames.com/rc/0ad-spirv.zip
    # Later this will get extracted directly into the AppDir
  fi
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
mkdir -p $APPDIR/usr/data/mods
cp -a binaries/data/mods/mod $APPDIR/usr/data/mods
if [ $svn -eq 1 ]; then
  mkdir -p $APPDIR/usr/data/mods/public
  $run_cmd "binaries/system/pyrogenesis -writableRoot  \
    -mod=mod   \
    -archivebuild=binaries/data/mods/public  \
    -archivebuild-output=$APPDIR/usr/data/mods/public/public.zip    \
    -archivebuild-compress" \
    && test -f "$APPDIR/usr/data/mods/public/public.zip"
  cp -a binaries/data/mods/public/mod.json $APPDIR/usr/data/mods/public
  unzip "$WORKSPACE/0ad-spirv.zip" -d $APPDIR/usr/data/mods/0ad-spirv
else
  cp -a binaries/data/mods/public $APPDIR/usr/data/mods
fi
# Create the image
cd "$WORKSPACE"

DEPLOY_GTK_VERSION=3 # Variable used by gtk plugin
ionice -c3 $TOOLS_DIR/squashfs-root/AppRun -d $APPDIR/usr/share/applications/0ad.desktop \
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

# This doesn't work because there is probably no such
# user inside the container.
#if [ -n "$HOSTUSER" ]; then
  #for file in 0ad*AppImage 0ad*.xz 0ad*.minisig  0ad*.sha1sum linuxdeploy-plugin-gtk.sh; do
    #chown $HOSTUSER "$file"
  #done
#fi

exit 0
