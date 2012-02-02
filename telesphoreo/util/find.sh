#!/bin/bash

#echo 1>&2
#echo ::: find.sh "$@" 1>&2

while [[ $# -ne 0 ]]; do
    if [[ $1 == /* ]]; then
        unset found

        found=$(echo "${PKG_PATH}:" | while IFS= read -r -d : path; do
            if [[ -e ${path}$1 ]]; then
                if [[ ${found+@} ]]; then
                    echo -n ':'
                else
                    found=
                fi

                echo -n "${path}$1"
            fi
        done)

        #echo "=== ${found:=$1}" 1>&2
        echo "${found:=$1}"
    else
        echo "$1"
    fi

    shift
done

#echo 1>&2
