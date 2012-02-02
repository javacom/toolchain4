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

. "${PKG_BASE}/helper.sh"

if [[ ! -x ${PKG_BASE}/util/arid || ${PKG_BASE}/util/arid -ot ${PKG_BASE}/util/arid.cpp ]]; then
    g++ -I "${PKG_BASE}"/util -o "${PKG_BASE}"/util/arid{,.cpp}
fi

if [[ ! -x ${PKG_BASE}/util/ldid || ${PKG_BASE}/util/ldid -ot ${PKG_BASE}/util/ldid.cpp ]]; then
    g++ -I "${PKG_BASE}"/util -o "${PKG_BASE}"/util/ldid{,.cpp} -x c "${PKG_BASE}"/util/{lookup2,sha1}.c
fi

export CODESIGN_ALLOCATE=$(which arm-apple-darwin9-codesign_allocate)

for DEP_NAME in "${PKG_DEPS[@]}"; do
    "${PKG_MAKE}" "${DEP_NAME}"
done

export PKG_HASH=$({
    "${PKG_BASE}"/util/catdir.sh "${PKG_DATA}" -L \( -name '.svn' -o -name '_*' \) -prune -o

    for DEP_NAME in "${PKG_DEPS[@]}"; do
        "${PKG_BASE}"/util/catdir.sh "$(PKG_DEST_ "${DEP_NAME}")"
        DEP_MORE="$(PKG_MORE_ "${DEP_NAME}")"
        if [[ -d ${DEP_MORE} ]]; then
            "${PKG_BASE}"/util/catdir.sh "${DEP_MORE}"
        fi
    done
} | md5sum | cut -d ' ' -f 1)

echo "hashed data ${PKG_NAME} to: ${PKG_HASH}"

if [[ -e "${PKG_STAT}/data-md5" && ${PKG_HASH} == $(cat "${PKG_STAT}/data-md5") ]]; then
    echo "skipping re-build of ${PKG_NAME}"
    exit
fi

mkdir -p "${PKG_STAT}"
rm -f "${PKG_STAT}/data-md5"

rm -rf "${PKG_MORE}"
mkdir -p "${PKG_MORE}"

rm -rf "${PKG_DEST}"
mkdir -p "${PKG_DEST}"

rm -rf "${PKG_WORK}"
mkdir -p "${PKG_WORK}"

function pkg:patch() {
    pkg:libtool_ libtool
    pkg:libtool_ ltmain.sh

    for diff in "${PKG_DATA}"/*.diff; do
        if [[ ${diff} =~ .*/_[^/]*.diff$ ]]; then
            continue;
        fi

        echo "patching with ${diff}..."
        patch -p1 <"${diff}"
    done
}

export -f pkg:patch

function pkg:bin() {
    if [[ $# -eq 0 ]]; then
        pushd "${PKG_DEST}/usr/bin"
        set $(ls)
        popd
    fi

    mkdir -p "${PKG_DEST}/bin"
    for bin in "$@"; do
        mv -v "${PKG_DEST}/usr/bin/${bin}" "${PKG_DEST}/bin/${bin}"
    done

    rmdir --ignore-fail-on-non-empty -p "${PKG_DEST}/usr/bin"
}

export -f pkg:bin

function pkg:autoconf() {
    for m4 in $(find -name "*.m4"); do
        patch -r/dev/null "${m4}" "${PKG_BASE}/util/libtool.m4.diff" || true
    done

    autoconf
}

export -f pkg:autoconf

export PKG_CONF=./configure

function pkg:libtool_() {
    for ltmain in $(find -name "$1"); do
        patch -r/dev/null "${ltmain}" "${PKG_BASE}/util/libtool.diff" || true
    done
}

export -f pkg:libtool_

function pkg:setup() {
    pkg:extract
    cd */
    pkg:patch
}

export -f pkg:setup

function pkg:configure() {
    MAKEINFO=$(which makeinfo) 
    PKG_CONFIG="$(realpath "${PKG_BASE}/util/pkg-config.sh")" \
    ac_cv_prog_cc_g=no ac_cv_prog_cxx_g=no \
    cfg=("${PKG_CONF}" \
        ac_cv_prog_cc_g=no ac_cv_prog_cxx_g=no \
        --build="$(${PKG_BASE}/util/config.guess)" \
        --host="${PKG_TARG}" \
        --enable-static=no \
        --enable-shared=yes \
        --prefix=$(cat "${PKG_BASE}/arch/${PKG_ARCH}/prefix") \
        --localstatedir="/var/cache/${PKG_NAME}" \
        "$@")
    echo "${cfg[@]}"
    "${cfg[@]}"
}

export -f pkg:configure

function pkg:make() {
    make AR="${PKG_TARG}-ar" CFLAGS='-O2 -mthumb'
}

export -f pkg:make

function pkg:install() {
    make install DESTDIR="${PKG_DEST}" "$@"
}

export -f pkg:install

function pkg:extract() {
    for tgz in "${PKG_DATA}"/*.{tar.gz,tgz}; do
        tar -zxf "${tgz}"
    done

    for zip in "${PKG_DATA}"/*.zip; do
        unzip "${zip}"
    done

    for tbz2 in "${PKG_DATA}"/*.tar.bz2; do
        tar -jxf "${tbz2}"
    done
}

export -f pkg:extract

function pkg:usrbin() {
    pkg: mkdir -p /usr/bin
    pkg: cp -a "$@" /usr/bin
}

export -f pkg:usrbin

cd "${PKG_WORK}"
"${PKG_BASE}/exec.sh" "${PKG_NAME}" . "${PKG_DATA}/make.sh"

function rmdir_() {
    if [[ -d "$1" ]]; then
        rmdir --ignore-fail-on-non-empty "$1"
    fi
}

rm -rf "${PKG_DEST}/usr/share/man"
rm -rf "${PKG_DEST}/usr/share/info"
rm -rf "${PKG_DEST}/usr/share/gtk-doc"
rm -rf "${PKG_DEST}/usr/share/doc"
rm -rf "${PKG_DEST}/usr/share/locale"
rm -rf "${PKG_DEST}/usr/man"
rm -rf "${PKG_DEST}/usr/local/share/man"
rm -rf "${PKG_DEST}/usr/local/OpenSourceVersions"
rm -rf "${PKG_DEST}/usr/local/OpenSourceLicenses"
rm -f "${PKG_DEST}/usr/lib/charset.alias"
rm -rf "${PKG_DEST}/usr/info"
rm -rf "${PKG_DEST}/usr/docs"
rm -rf "${PKG_DEST}/usr/doc"

rmdir_ "${PKG_DEST}/usr/share"
rmdir_ "${PKG_DEST}/usr/local/share"
rmdir_ "${PKG_DEST}/usr/local"
rmdir_ "${PKG_DEST}/usr/lib"
rmdir_ "${PKG_DEST}/usr"

if [[ -e "${PKG_BASE}/arch/${PKG_ARCH}/strip" ]]; then
    . "${PKG_BASE}/arch/${PKG_ARCH}/strip"
fi

find "${PKG_DEST}" -type f -name '*.elc' -print0 | while read -r -d $'\0' bin; do
    sed -i -e '
        s/^;;; Compiled by .*$//
        s/^;;; from file .*$//
        s/^;;; in Emacs version .*$//
        s/^;;; with .*$//
    ' "${bin}"
done

find "${PKG_DEST}" -type f -name '*.a' -print0 | while read -r -d $'\0' bin; do
    "${PKG_BASE}/util/arid" "${bin}"
done

cp -aL "${PKG_DATA}/_metadata/version" "${PKG_STAT}/data-ver"
echo "${PKG_HASH}" >"${PKG_STAT}/data-md5"

echo "hashed code ${PKG_NAME} to: $("${PKG_BASE}"/util/catdir.sh "${PKG_DEST}" | md5sum | cut -d ' ' -f 1)"
