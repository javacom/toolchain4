#!/bin/bash
rm -f stat/${PKG_ARCH}/$1/data-md5
./make.sh "$1"
