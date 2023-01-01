#!/bin/bash
set -ev

if [ -z "$WORKSPACE" ]; then
  echo "WORKSPACE must be set"
  exit 1
fi
cd $WORKSPACE
if [ ! -e "AppRun" ]; then
  echo "You must be in the same directory where the AppRun file resides"
  exit 1
fi

# Get, check, and extract source
source=$NAME-$VERSION-unix-build.tar.xz
source_uri=$URI/$source
source_sum=$source.sha1sum
source_sum_uri=$URI/$source_sum
source_minisig=$source.minisig
source_minisig_uri=$URI/$source_minisig

for file in $source $source_sum; do
  if [ ! -e $file ]; then
    wget -nv $file
  fi
done

if [ -n "${URI##*/rc*}" ]; then
  wget -nc $source_minisig_uri
  $MINISIGN_PATH -Vm $source -P $MINISIGN_KEY
fi

sha1sum -c $source_sum
cd $BUILD_DIR
su 0ad --command "tar xJf $WORKSPACE/$source"

# name: build
cd $NAME-$VERSION/build/workspaces
su 0ad --command "./update-workspaces.sh \
  -j$(nproc) && \
  make config=release -C gcc -j$(nproc)"

# name: prepare AppDir
cd $WORKSPACE
# Get, check, and extract data
data=$NAME-$VERSION-unix-data.tar.xz
data_uri=$URI/$data
data_sum=$data.sha1sum
data_sum_uri=$URI/$data_sum
echo "Getting data and extracting archive..."
for file in $data_uri $data_sum_uri; do
  if [ ! -e $file ]; then
    wget -nv $file
  fi
done

if [ -n "${URI##*/rc*}" ]; then
  wget -nv $URI/$NAME-$VERSION-unix-data.tar.xz.minisig
fi

$MINISIGN_PATH -Vm $data -P $MINISIGN_KEY
sha1sum -c $data_sum
su 0ad --command "tar xJf $data -C $BUILD_DIR"
ABS_PATH_SRC_ROOT="$BUILD_DIR/$NAME-$VERSION"
#if [ ! -d "$ABS_PATH_WORK_DIR" ]; then
  #echo "The work dir must be an absolute path to an existing directory."
  #exit 1
#fi
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
cd $WORKSPACE
mv $TOOLS_DIR/linuxdeploy-plugin-gtk.sh .
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
mv 0_A.D.-$VERSION-$ARCH.AppImage $NAME-$VERSION-$DATE_STR-$ARCH.AppImage
echo "Generating sha1sum..."
sha1sum $NAME-$VERSION-$DATE_STR-$ARCH.AppImage > $NAME-$VERSION-$DATE_STR-$ARCH.AppImage.sha1sum
