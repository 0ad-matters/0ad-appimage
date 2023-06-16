#!/bin/bash

cmp_substr () {
  if [ -z "$1" -o -z "$2" ]; then
    return 1
  fi
  [ -z "${1##*$2*}" ]
  return $?
}

# 0ad signing keys
# key for a26
MINISIGN_KEY=RWTWLbO12+ig3lUExIor3xd6DdZaYFEozn8Bu8nIzY3ImuRYQszIQyyy
# key for a25
# MINISIGN_KEY=RWT0hFWv57I2RFoJwLVjxEr44JOq/RkEx1oT0IA3PPPICnSF7HFKW1CT

export -p

# This var is set in the the docker container
if [ -z "DOCKER_0AD_BUILD" ]; then
  echo "This script is intended to be run inside a docker container."
  echo "(hint: andy5995/0ad-build-env:focal)"
  exit 1
fi

set -ev

test -n "$VERSION"
test -n "$WORKSPACE"
APPDIR="$WORKSPACE/AppDir"
URI=https://releases.wildfiregames.com/rc

svn=1
cmp_substr "$VERSION" "svn" || svn=0

cd $WORKSPACE
if [ ! -e "AppRun" ]; then
  echo "You must be in the same directory where the AppRun file resides"
  exit 1
fi

if [ -d "$APPDIR" ]; then
  rm -rf "$APPDIR"
else
  mkdir -v -p "$APPDIR"
fi

if [ $svn -ne 1 ]; then
  ABS_PATH_SRC_ROOT="$WORKSPACE/0ad-$VERSION"
else
  ABS_PATH_SRC_ROOT="$WORKSPACE/0ad-svn"
fi

cd "$WORKSPACE"

# The gtk plugin is placed in this directory because this is where linuxdeploy
# is run from later to create the AppImage. In this location, the plugin will
# be visible to linuxdeploy when the AppImage is created
if [ ! -r linuxdeploy-plugin-gtk.sh ]; then
  curl -LO https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gtk/master/linuxdeploy-plugin-gtk.sh
  chmod +x linuxdeploy-plugin-gtk.sh
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

  #if [ -n "${URI##*/rc*}" ]; then
    #if [ ! -r $URI/$source.minisig ]; then
      #curl -LO $URI/$source.minisig
    #fi
    #$MINISIGN_PATH -Vm $source -P $MINISIGN_KEY
  #fi
  sha1sum -c $source_sum
  tar xJf $WORKSPACE/$source
else
  if [ ! -r "0ad-svn" ]; then
    svn --quiet co https://svn.wildfiregames.com/public/ps/trunk/ 0ad-svn
    cd 0ad-svn
  else
    cd "$WORKSPACE/0ad-svn"
    svn --quiet up
  fi
  VERSION="$VERSION-r$(svn info --show-item revision)"
fi

# name: build
if [ ! -r "$ABS_PATH_SRC_ROOT/source/main.cpp" ]; then
  echo "set the source root!"
  exit 1
fi
cd "$ABS_PATH_SRC_ROOT/build/workspaces"

/bin/bash -c 'ionice -c3 nice -n 19 \
  ./update-workspaces.sh \
    -j$(nproc) && \
  make config=release -C gcc -j$(nproc)'

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

  #if [ -n "${URI##*/rc*}" ] && [ ! -r $URI/$data.minisig ]; then
      #curl -LO $URI/$data.minisig
  #fi

  #$MINISIGN_PATH -Vm $data -P $MINISIGN_KEY
  sha1sum -c $data_sum
  tar xJf $data
fi

cd "$ABS_PATH_SRC_ROOT"
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

# Hopefully prevent out-of-space failure when running on a GitHub hosted runner
if [ -n "${GITHUB_ACTIONS}" ]; then
  cd "${ABS_PATH_SRC_ROOT}/build/workspaces"
  ./clean-workspaces.sh
fi

cd $ABS_PATH_SRC_ROOT
if [ $svn -eq 1 ]; then
  mkdir -p $APPDIR/usr/data/mods/public
  binaries/system/pyrogenesis -writableRoot  \
    -mod=mod   \
    -archivebuild=binaries/data/mods/public  \
    -archivebuild-output=$APPDIR/usr/data/mods/public/public.zip    \
    -archivebuild-compress \
    && test -f "$APPDIR/usr/data/mods/public/public.zip"
  cp -a binaries/data/mods/public/mod.json $APPDIR/usr/data/mods/public
else
  cp -a binaries/data/mods/public $APPDIR/usr/data/mods
fi

# spirv. See https://wildfiregames.com/forum/topic/104382-vulkan-new-graphics-api/
mkdir $APPDIR/usr/data/mods/0ad-spirv
cd $APPDIR/usr/data/mods/0ad-spirv
curl -LO https://releases.wildfiregames.com/rc/0ad-spirv.zip
curl -LO https://releases.wildfiregames.com/rc/0ad-spirv.zip.sha1sum
sha1sum -c 0ad-spirv.zip.sha1sum
rm 0ad-spirv.zip.sha1sum
unzip 0ad-spirv.zip mod.json

cd "$WORKSPACE"

# Hopefully prevent out-of-space failure when running on a GitHub hosted runner
echo "Removing data from source tree (already copied to ${APPDIR})..."
if [ -n "${GITHUB_ACTIONS}" ]; then
  rm -rf "${ABS_PATH_SRC_ROOT}/binaries/data"
fi

# Create the image
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
OUT_APPIMAGE="0ad-$VERSION-$DATE_STR-$UBUNTU_CODENAME-$ARCH.AppImage"
mv 0_A.D.-$VERSION-$ARCH.AppImage $OUT_APPIMAGE
echo "Generating sha1sum..."
sha1sum $OUT_APPIMAGE > "$OUT_APPIMAGE.sha1sum"
cat "$OUT_APPIMAGE.sha1sum"

exit 0
