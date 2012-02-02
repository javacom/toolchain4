#!/bin/bash
set -e
shopt -s extglob nullglob

export PKG_NAME=${1%_}
export PKG_BASE=$(realpath "$(dirname "$0")")
export PATH=${PKG_BASE}/util:$PATH
shift

source "${PKG_BASE}/helper.sh"
export PKG_TAPF=$(cat "${PKG_BASE}/arch/${PKG_ARCH}/prefix")

PKG_PATH=

PKG_INCL=
PKG_LIBS=
PKG_PKGS=

if [[ -n ${FAKEROOTKEY} ]]; then
    for i in "$(dirname $(which fakeroot))"/../lib{64,32,}/libfakeroot; do
        PKG_LIBS=$i:${PKG_LIBS}
    done
fi

case "${PKG_NAME}" in
    (-) deps=();;
    (:*) deps=(${PKG_NAME//:/ });;
    (*) deps=($({
        find -L "${PKG_DATA}"/_metadata -name '*.dep' -exec basename {} .dep \;
    } | sort -u));;
esac

for dep in ${deps[@]}; do
    # XXX: bother dealing with weird arguments?
    #DEP_NAME=$(basename "${dep}" .dep)
    DEP_NAME=${dep}
    DEP_MORE=$(PKG_MORE_ "${DEP_NAME}")
    DEP_DEST=$(PKG_DEST_ "${DEP_NAME}")
    PKG_PATH=${PKG_PATH}:${DEP_DEST}

    if [[ -d ${DEP_DEST}${PKG_TAPF}/include ]]; then
        PKG_INCL=${DEP_DEST}${PKG_TAPF}/include:${PKG_INCL}
    fi

    if [[ -d ${DEP_DEST}${PKG_TAPF}/lib ]]; then
        PKG_LIBS=${DEP_DEST}${PKG_TAPF}/lib:${PKG_LIBS}
    fi

    if [[ -d ${DEP_MORE}${PKG_TAPF}/lib ]]; then
        PKG_LIBS=${DEP_MORE}${PKG_TAPF}/lib:${PKG_LIBS}
    fi

    if [[ -d ${DEP_DEST}${PKG_TAPF}/lib/pkgconfig ]]; then
        PKG_PKGS=${DEP_DEST}${PKG_TAPF}/lib/pkgconfig:${PKG_PKGS}
    fi
done

PKG_PATH=${PKG_PATH}:${PKG_ROOT}
export PKG_PATH=${PKG_PATH#:}

PKG_INCL=${PKG_INCL%:}
PKG_LIBS=${PKG_LIBS%:}
PKG_PKGS=${PKG_PKGS%:}

CODESIGN_ALLOCATE=$(which "${PKG_TARG}"-codesign_allocate) \
C_INCLUDE_PATH= \
COMPILER_PATH=${PKG_BASE}/util \
CPATH=/dat/git/iphone-api:${PKG_INCL} \
CPLUS_INCLUDE_PATH= \
LD_LIBRARY_PATH=${PKG_LIBS} \
LIBRARY_PATH=${PKG_LIBS} \
MIGCC=${PKG_TARG}-gcc \
PKG_CONFIG_PATH=${PKG_PKGS} \
LD_TWOLEVEL_NAMESPACE= \
    "$@"
