#!/bin/bash
set -e
shopt -s extglob nullglob

PKG_BASE=$(dirname "$(realpath "$0")")
cd "${PKG_BASE}"
PKG_RVSN=282

PKG_REPO=/dat/web/beta.apt.saurik.com

for PKG_ARCH in "${PKG_BASE}/arch"/*; do
    PKG_ARCH=$(basename "${PKG_ARCH}")
    echo "scanning ${PKG_ARCH}"

    PKG_DCBF=${PKG_REPO}/dists/tangelo/main/binary-${PKG_ARCH}
    mkdir -p "${PKG_DCBF}"
    PKG_PKGS=${PKG_DCBF}/Packages

    rm -rf "${PKG_BASE}/link"
    mkdir "${PKG_BASE}/link"

    for package in "${PKG_BASE}/data"/!(*_); do
        PKG_NAME=$(basename "${package}")

        # XXX: add to above filter
        if [[ ${PKG_NAME} == _* ]]; then
            continue
        fi

        PKG_DATA="${PKG_BASE}/data/${PKG_NAME}"
        PKG_STAT="${PKG_BASE}/stat/${PKG_ARCH}/${PKG_NAME}"
        PKG_PRIO=$(cat "${PKG_DATA}/_metadata/priority")

        if [[ -e ${PKG_STAT}/fail ]]; then
            continue
        fi

        echo "${PKG_NAME}" "${PKG_PRIO#+}" "$(cat "${PKG_DATA}/_metadata/section")"

        PKG_FILE=${PKG_BASE}/stat/${PKG_ARCH}/${PKG_NAME}/dest-ver
        if [[ -e ${PKG_FILE} ]]; then
            PKG_REAL=${PKG_BASE}/stat/${PKG_ARCH}/${PKG_NAME}/real-ver
            if [[ -e ${PKG_REAL} ]]; then
                PKG_RVER=$(cat "${PKG_REAL}")
            else
                PKG_RVER=$(cat "${PKG_STAT}/data-ver")-$(cat "${PKG_FILE}")
            fi

            PKG_FILE=${PKG_BASE}/debs/${PKG_NAME}_${PKG_RVER}_${PKG_ARCH}.deb
            if [[ -e ${PKG_FILE} && ! -e "${PKG_STAT}/exclude" ]]; then
                ln -s "${PKG_FILE}" "${PKG_BASE}/link"
                echo "${PKG_FILE}"
            fi
        fi
    done >"${PKG_BASE}/overrides.txt"

    for deb in "${PKG_BASE}/xtra/${PKG_ARCH}"/*.deb; do
        ln -s "$(readlink -f "${deb}")" "${PKG_BASE}/link"
    done

    dpkg-scanpackages -m link "${PKG_BASE}/overrides.txt" | sed -e 's/: link\//: debs\//' | while IFS= read -r line; do
        if [[ ${line} == '' ]]; then
            PKG_TAGS=$(cat "${PKG_BASE}/tags/${PKG_NAME}" 2>/dev/null || true)
            if [[ -z ${PKG_TAGS} ]]; then
                PKG_TAGS=$(cat "${PKG_BASE}/data/${PKG_NAME}/_metadata/tags" 2>/dev/null || true)
            fi
            PKG_ROLE="${PKG_BASE}/data/${PKG_NAME}/_metadata/role"
            if [[ -n ${PKG_TAGS} || -e ${PKG_ROLE} ]]; then
                echo -n "Tag: "
                if [[ -n ${PKG_TAGS} ]]; then
                    echo -n "${PKG_TAGS}"
                fi
                if [[ -n ${PKG_TAGS} && -e ${PKG_ROLE} ]]; then
                    echo -n ", "
                fi
                if [[ -e ${PKG_ROLE} ]]; then
                    echo -n "role::$(cat "${PKG_ROLE}")"
                fi
                echo
            fi
        elif [[ ${line} == Package:* ]]; then
            PKG_NAME=${line#Package: }
        fi

        echo "${line}"
    done >"${PKG_PKGS}"

    if [[ ${PKG_ARCH} == "iphoneos-arm" ]]; then
        dpkg-scanpackages paid >>"${PKG_PKGS}"
    fi

    rm -f "${PKG_BASE}/overrides.txt"
done

for PKG_ARCH in "${PKG_BASE}/arch"/*; do
    PKG_ARCH=$(basename "${PKG_ARCH}")
    PKG_PKGS=${PKG_REPO}/dists/tangelo/main/binary-${PKG_ARCH}/Packages
    bzip2 -c "${PKG_PKGS}" >"${PKG_PKGS}.bz2"
done

cd "${PKG_REPO}/dists/tangelo"

{
    cat <<EOF
Origin: Telesphoreo Tangelo
Label: Cydia/Telesphoreo
Suite: stable
Version: 1.0r${PKG_RVSN}
Codename: tangelo-3.7
Architectures:$(for PKG_ARCH in "${PKG_BASE}/arch"/*; do echo -n " $(basename "${PKG_ARCH}")"; done)
Components: main
Description: Distribution of Unix Software for iPhoneOS 3
Support: http://cydia.saurik.com/support/*
MD5Sum:
EOF

    find */* -type f | while read -r line; do
        echo " $(md5sum "${line}" | cut -d ' ' -f 1) $(du -b "${line}" | cut -d $'\t' -f 1) ${line}"
    done

} >"Release"

rm -f Release.gpg
gpg -abs -o Release.gpg Release
