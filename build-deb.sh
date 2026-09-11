#!/bin/sh
set -e
cd "$(dirname "$0")"
PKG=com.local.tube
VER=$(grep '^Version:' control | awk '{print $2}')
STAGE=_stage
rm -rf $STAGE
mkdir -p $STAGE/Applications/Tube.app $STAGE/DEBIAN
chmod 0755 update-yt-dlp.sh layout/DEBIAN/postinst
cp Resources/Info.plist Resources/Icon*.png $STAGE/Applications/Tube.app/
cp DEBIAN/control $STAGE/DEBIAN/control
cp layout/DEBIAN/postinst $STAGE/DEBIAN/postinst
chmod 0755 $STAGE/DEBIAN/postinst
if [ -f Tube ]; then cp Tube $STAGE/Applications/Tube.app/Tube; chmod 0755 $STAGE/Applications/Tube.app/Tube; fi
find $STAGE -name ".DS_Store" -delete
if command -v dpkg-deb >/dev/null; then dpkg-deb -Zgzip -b $STAGE ${PKG}_${VER}_iphoneos-arm.deb
else echo "dpkg-deb missing: stage ready in $STAGE (install dpkg via brew install dpkg)"; fi
