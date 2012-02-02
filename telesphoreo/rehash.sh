#!/bin/bash
set -e
shopt -s extglob nullglob

if [[ $# == 0 ]]; then
    echo "usage: $0 <package>"
    exit
fi

export PKG_MAKE=$0
export PKG_NAME=${1%_}

export PKG_BASE=$(realpath "$(dirname "$0")")
source "${PKG_BASE}/helper.sh"

./make.sh "${PKG_NAME}"

pkg: mkdir -p /DEBIAN
./control.sh "${PKG_NAME}" control >"$(pkg_ /DEBIAN/control)"

if [[ -e "${PKG_DATA}"/_metadata/preinst ]]; then
    cp -a "${PKG_DATA}"/_metadata/preinst "$(pkg_ /DEBIAN)"
fi

if [[ -e "${PKG_DATA}"/_metadata/postinst ]]; then
    cp -a "${PKG_DATA}"/_metadata/postinst "$(pkg_ /DEBIAN)"
fi

if [[ -e "${PKG_DATA}"/_metadata/prerm ]]; then
    cp -a "${PKG_DATA}"/_metadata/prerm "$(pkg_ /DEBIAN)"
fi

export PKG_HASH=$(util/catdir.sh "${PKG_DEST}" | md5sum | cut -d ' ' -f 1)
echo "hashed dest ${PKG_NAME} to: ${PKG_HASH}"
echo "${PKG_HASH}" >"${PKG_STAT}/dest-md5"

pkg: rm -rf /DEBIAN
