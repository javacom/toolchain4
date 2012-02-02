#!/bin/bash
OPTIND=1
while getopts mnprsv OPTKEY; do
    case $OPTKEY in
        (m) echo 'iPhone1,1';;
        (n) echo 'transponder';;
        (p) echo 'unknown';;
        (r) echo '9.0.0d1';;
        (s) echo 'Darwin';;
        (v) echo 'Darwin Kernel Version 9.0.0d1: Wed Sep 19 00:08:43 PDT 2007; root:xnu-933.0.0.203.obj~21/RELEASE_ARM_S5L8900XRB';;
    esac
done
