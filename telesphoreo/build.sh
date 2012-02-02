#!/bin/bash
set -e
shopt -s extglob
#for package in coreutils berkeleydb bzip2 apt adv-cmds libutil gettext gawk tar network-cmds shell-cmds odcctools readline modmyifone darwintools sed pcre gnupg grep inetutils saurik gzip dpkg iphonesurge unzip libarmfp nano base bash system-cmds libresolv zip ncurses less; do
for package in data/!(*_|apptapptools|gdata-objectivec-client|iphone-python|metasploit3|mobileterminal|jocstrap|iphone-java|uicaboodle|uicaboodle.py|uikittools|x264); do
#for package in data/!(*_); do
    PKG_NAME=$(basename "${package}")
    echo "========== ${PKG_NAME} =========="
    ./package.sh "${PKG_NAME}"
done
