#!/bin/bash
for ltmain in $(find -name ltmain.sh); do
    patch -N "${ltmain}" "$(dirname "$0")/libtool.diff" || true
done

if [[ -z $PKG_CONF ]]; then
    PKG_CONF=./configure
fi

PKG_ROOT=/home/saurik/iphone/sysroot PKG_CONFIG="$(realpath ../../../util/pkg-config.sh) --define-variable=prefix=/home/saurik/iphone/sysroot/usr" PKG_CONFIG_PATH=/home/saurik/iphone/sysroot/usr/lib/pkgconfig $PKG_CONF --prefix=/usr --host=arm-apple-darwin9 --enable-static=no --enable-shared=yes "$@"
