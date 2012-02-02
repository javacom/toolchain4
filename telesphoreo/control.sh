#!/bin/bash
shopt -s extglob nullglob

export PKG_NAME=$1
shift

export PKG_BASE=$(realpath "$(dirname "$0")")
. "${PKG_BASE}/helper.sh"

if [[ -n $2 ]]; then
    PKG_VRSN=$2
fi

cat <<EOF
Package: ${PKG_NAME}
EOF

if [[ ${PKG_PRIO} == +* ]]; then
    cat <<EOF
Essential: yes
EOF
fi

if [[ $1 == status ]]; then
    cat <<EOF
Status: install ok installed
EOF
fi

cat <<EOF
Priority: ${PKG_PRIO#+}
Section: $(cat "${PKG_DATA}/_metadata/section")
EOF

if [[ $1 == status || $1 == available ]]; then
    cat <<EOF
Installed-Size: $(dpkg -f "${PKG_BASE}/debs/${PKG_NAME}_${PKG_VRSN}-${PKG_RVSN}_${PKG_ARCH}.deb" Installed-Size)
EOF
elif [[ $1 == control ]]; then
    cat <<EOF
Installed-Size: $(du -s "${PKG_DEST}" | cut -d $'\t' -f 1)
EOF
fi

cat <<EOF
Maintainer: $(cat "${PKG_DATA}/_metadata/maintainer")
Architecture: ${PKG_ARCH}
EOF

echo -n "Version: ${PKG_VRSN}"

if [[ $1 == status || $1 == available ]]; then
    echo "-${PKG_RVSN}"
else
    echo
fi

if [[ $1 == available ]]; then
    cat <<EOF
Size: $(find "${PKG_DEST}" -type f -exec cat {} \; | gzip -c | wc -c | cut -d $'\t' -f 1)
EOF
fi

if [[ -e ${PKG_DATA}/_metadata/predepends_ ]]; then
    echo "Pre-Depends: $(cat "${PKG_DATA}/_metadata/predepends_")"
else
    unset comma

    if [[ ${PKG_ZLIB} == lzma ]]; then
        if [[ ${comma+@} == @ ]]; then
            echo -n ","
        else
            echo -n "Pre-Depends:"
            comma=
        fi

        echo -n " dpkg (>= 1.14.25-8)"
    fi

    if [[ -e ${PKG_DATA}/_metadata/predepends ]]; then
        if [[ ${comma+@} == @ ]]; then
            echo -n ","
        else
            echo -n "Pre-Depends:"
            comma=
        fi

        echo -n " $(cat "${PKG_DATA}/_metadata/predepends")"
    fi

    if [[ ${comma+@} == @ ]]; then
        echo
    fi
fi

if [[ ! -e ${PKG_DATA}/_metadata/depends_ ]]; then
    unset comma
    for dep in "${PKG_DEPS[@]}"; do
        if [[ ${dep} == _* ]]; then
            continue
        fi

        if [[ ${comma+@} == @ ]]; then
            echo -n ","
        else
            echo -n "Depends:"
            comma=
        fi

        echo -n " $(basename "${dep}" .dep)"
        
        ver=${PKG_DATA}/_metadata/${dep%.dep}.ver.${PKG_ARCH}
        if [[ -e "${ver}" ]]; then
            echo -n " (>= $(cat "${ver}"))"
        fi
    done

    if [[ -e ${PKG_DATA}/_metadata/depends ]]; then
        if [[ ${comma+@} == @ ]]; then
            echo -n ","
        else
            echo -n "Depends:"
            comma=
        fi

        echo -n " $(cat "${PKG_DATA}/_metadata/depends")"
    fi

    if [[ ${comma+@} == @ ]]; then
        echo
    fi
elif [[ -s ${PKG_DATA}/_metadata/depends_ ]]; then
    echo "Depends: $(cat "${PKG_DATA}/_metadata/depends_")"
fi

if [[ -e ${PKG_DATA}/_metadata/replaces ]]; then
    cat <<EOF
Replaces: $(cat "${PKG_DATA}/_metadata/replaces")
EOF
fi

if [[ -e ${PKG_DATA}/_metadata/conflicts ]]; then
    cat <<EOF
Conflicts: $(cat "${PKG_DATA}/_metadata/conflicts")
EOF
fi

if [[ -e ${PKG_DATA}/_metadata/provides ]]; then
    cat <<EOF
Provides: $(cat "${PKG_DATA}/_metadata/provides")
EOF
fi

cat <<EOF
Description: $(head -n 1 "${PKG_DATA}/_metadata/description")
EOF

if [[ $(wc -l "${PKG_DATA}/_metadata/description" | cut -d ' ' -f 1) -gt 1 ]]; then
    cat <<EOF
$(tail -n +2 "${PKG_DATA}/_metadata/description" | fold -sw 72 | sed -e 's/^/ /')
EOF
fi

if [[ -e ${PKG_DATA}/_metadata/name ]]; then
    cat <<EOF
Name: $(cat "${PKG_DATA}/_metadata/name")
EOF
fi

if [[ -e ${PKG_DATA}/_metadata/author ]]; then
    cat <<EOF
Author: $(cat "${PKG_DATA}/_metadata/author")
EOF
fi

if [[ -e ${PKG_DATA}/_metadata/homepage ]]; then
    cat <<EOF
Homepage: $(cat "${PKG_DATA}/_metadata/homepage")
EOF
fi

if [[ -e ${PKG_DATA}/_metadata/depiction ]]; then
    cat <<EOF
Depiction: $(cat "${PKG_DATA}/_metadata/depiction")
EOF
fi

if [[ $1 == status || $1 == available ]]; then
    echo
fi
