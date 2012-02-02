#!/bin/bash

function PKG_DATA_() {
    echo "${PKG_BASE}/data/$1"
}

export -f PKG_DATA_

function PKG_WORK_() {
    echo "${PKG_BASE}/work/${PKG_ARCH}/$1"
}

export -f PKG_WORK_

function PKG_MORE_() {
    echo "${PKG_BASE}/more/${PKG_ARCH}/$1"
}

function PKG_DEST_() {
    echo "${PKG_BASE}/dest/${PKG_ARCH}/$1"
}

export -f PKG_DEST_

function pkg_ {
    case "${1:0:1}" in
        (/) echo "${PKG_DEST}$1";;
        (@) echo "${PKG_MORE}${1:1}";;
        (%) echo "${PKG_DATA}${1:1}";;
        (*) echo -"$1" | sed -e 's/^.//';;
    esac
}

export -f pkg_

function pkg: {
    declare -a argv
    declare argc=$#

    for ((i=0; $i != $argc; ++i)); do
        argv[$i]=$(pkg_ "$1")
        shift
    done

    "${argv[@]}"
}

export -f pkg:
