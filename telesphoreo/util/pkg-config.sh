#!/bin/bash

#echo 1>&2
#echo ::: "$@" 1>&2

declare -a args
declare -a pkgs
unset dbpf

while [[ $# -ne 0 ]]; do case "$1" in
    (--atleast-pkgconfig-version)
        exec pkg-config "$1" "$2"
    ;;

    (--cflags|--libs|--variable=*)
        dbpf=
        args[${#args[@]}]=$1
    ;;

    (--errors-to-stdout|--exists|--modversion|--print-errors|--short-errors|--uninstalled)
        args[${#args[@]}]=$1
    ;;

    (--atleast-version|--exact-version|--max-version)
        args[${#args[@]}]=$1
        args[${#args[@]}]=$2
        shift
    ;;

    (--*)
        echo "unknown pkg-config option $1" 1>&2
        exit 1
    ;;

    (*)
        pkgs[${#pkgs[@]}]=$1
    ;;
esac; shift; done

if [[ ${dbpf+@} ]]; then
    source "${PKG_BASE}/folders.sh"
fi

outs=
for pkg in "${pkgs[@]}"; do
    args_=("${args[@]}")

    if [[ ${dbpf+@} ]]; then
        dest=$(for dep in $(find -L "${PKG_DATA}"/_metadata -name '*.dep' | cut -d '/' -f -); do
            DEP_NAME=$(basename "${dep}" .dep)
            DEP_DEST=$(PKG_DEST_ "${DEP_NAME}")

            find "${DEP_DEST}" -name "${pkg}.pc" -printf "${DEP_DEST}\n"
        done) && args_=(--define-variable=prefix="${dest}/usr" "${args_[@]}")
    fi

    #echo @@@ pkg-config "${args_[@]}" "${pkg}" 1>&2
    out=$(pkg-config "${args_[@]}" "${pkg}") || exit $?
    #echo "=== ${out}" 1>&2
    outs+=\ ${out}
done

echo "${out#\ }"
