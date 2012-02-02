#!/bin/bash
set -e
shopt -s extglob nullglob

export PKG_BASE=$(realpath "$(dirname "$0")")
source "${PKG_BASE}/architect.sh"

export PKG_BOOT=${PKG_BASE}/Packager

rm -rf "${PKG_BOOT}"
svn export "${PKG_BASE}/over" "${PKG_BOOT}"

mkdir -p "${PKG_BOOT}/var/lib/dpkg/info"

#PKG_REQS=(apt7)
#PKG_REQS=(adv-cmds apt7 base coreutils cydia cydia-sources diffutils diskdev-cmds essential findutils firmware-sbin grep inetutils less network-cmds openssh pam-modules profile.d sed sqlite3-lib system-cmds uikittools unzip wget zip)
#PKG_REQS=(base cydia-sources dpkg essential firmware-sbin openssh pam-modules profile.d system-cmds wget)
#PKG_REQS=(adv-cmds apt7 base coreutils cydia-sources diffutils diskdev-cmds findutils firmware-sbin grep inetutils less network-cmds openssh pam-modules profile.d sed sqlite3-lib system-cmds unzip wget zip)
PKG_REQS=(adv-cmds apr-lib apt7 base coreutils cydia-sources darwintools diffutils diskdev-cmds essential findutils firmware-sbin grep inetutils less network-cmds openssh pam-modules pcre profile.d sed shell-cmds sqlite3-lib system-cmds unzip wget zip)
#PKG_REQS=(base cydia cydia-sources diskdev-cmds essential firmware-sbin pam-modules profile.d sqlite3-lib system-cmds uikittools libxml2-lib yellowsn0w.com)

cd "${PKG_BASE}/data"
PKG_REQS=($({
    echo "${PKG_REQS[@]}" | tr ' ' $'\n'
    find -L "${PKG_REQS[@]}" -name '*.dep' | grep -v '/_[^/]*\.dep' | sed -e 's/.*\/\([^\/]*\)\.dep/\1/'
} | sort -u | grep -Ev '^(libxml2|sqlite3)-dylib$'))

function merge() {
    deb=$1
    name=$2

    rm -rf "${PKG_BASE}/temp"
    dpkg -x "${deb}" "${PKG_BASE}/temp"

    files=("${PKG_BASE}/temp"/*)
    if [[ ${#files[@]} -ne 0 && ${name} != firmware-sbin ]]; then
        cp -a "${PKG_BASE}/temp"/* "${PKG_BOOT}"
    fi

    (cd "${PKG_BASE}/temp"; find | sed -e '
        s/^\.\///
        s/^/\//
    ') >"${PKG_BOOT}/var/lib/dpkg/info/${name}.list"
}

for PKG_NAME in "${PKG_REQS[@]}"; do
    PKG_NAME=${PKG_NAME%/_metadata/priority}
    PKG_NAME=${PKG_NAME##*/}

    cd "${PKG_BASE}"
    #./package.sh "${PKG_NAME}"
    source "${PKG_BASE}/helper.sh"

    echo "merging ${PKG_NAME} ${PKG_VRSN}-${PKG_RVSN}..."
    merge "${PKG_BASE}/debs/${PKG_NAME}_${PKG_VRSN}-${PKG_RVSN}_${PKG_ARCH}.deb" "${PKG_NAME}"

    "${PKG_BASE}/control.sh" "${PKG_NAME}" available >>"${PKG_BOOT}/var/lib/dpkg/available"
    "${PKG_BASE}/control.sh" "${PKG_NAME}" status >>"${PKG_BOOT}/var/lib/dpkg/status"
done

merge debs/cydia_1.0.3366-1_iphoneos-arm.deb cydia
merge debs/uikittools_1.1.0_iphoneos-arm.deb uikittools

rm -rf "${PKG_BASE}/temp"
cd "${PKG_BOOT}"

"${PKG_BASE}"/fix.sh

PKG_RSLT="${PKG_BASE}/rslt"
mkdir -p "${PKG_RSLT}"

rm -rf "${PKG_RSLT}/CydiaInstaller.bundle"
mkdir "${PKG_RSLT}/CydiaInstaller.bundle"

mkdir "${PKG_RSLT}/CydiaInstaller.bundle/files"
cp -a * "${PKG_RSLT}/CydiaInstaller.bundle/files"

{
    cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Name</key>
    <string>Cydia Installer</string>
    <key>Identifier</key>
    <string>org.saurik.cydia</string>
    <key>Description</key>
    <string>Unix Subsystem w/ Advanced Installer</string>
    <key>SupportedFirmware</key>
    <array>
EOF

    cat "${PKG_BASE}/arch/${PKG_ARCH}/firmware" | sed -e '
        s/^/        <string>/
        s/$/<\/string>/
    '

    cat <<EOF
    </array>
    <key>Commands</key>
    <array>
EOF

    find \( -not -uid 0 -o -not -gid 0 \) -printf '%U %G %p\n' | while IFS= read -r line; do
        set ${line}

        cat <<EOF
        <dict>
            <key>Action</key>
            <string>SetOwner</string>
            <key>File</key>
            <string>${3#./}</string>
            <key>Owner</key>
            <string>$1:$2</string>
        </dict>
EOF
    done

    find -perm /6000 -printf '%m %p\n' | while IFS= read -r line; do
        set ${line}

        cat <<EOF
        <dict>
            <key>Action</key>
            <string>SetPermission</string>
            <key>File</key>
            <string>${2#./}</string>
            <key>Permission</key>
            <string>$1</string>
        </dict>
EOF
    done

    cat <<EOF
        <dict>
            <key>Action</key>
            <string>RunScript</string>
            <key>File</key>
            <string>space.sh</string>
        </dict>
    </array>
    <key>Size</key>
    <integer>$(du -bs "${PKG_RSLT}/CydiaInstaller.bundle/files" | cut -d $'\t' -f 1)</integer>
</dict>
</plist>
EOF
} >"${PKG_RSLT}/CydiaInstaller.bundle/Info.plist"

cp -a "${PKG_BASE}"/pwnr/* "${PKG_RSLT}"/CydiaInstaller.bundle
tar -zcf "${PKG_RSLT}/Pwnage_${PKG_ARCH}.tgz" -C "${PKG_RSLT}" CydiaInstaller.bundle

function stash() {
    src=$1
    dst=var/stash/${src##*/}
    mv "${src}" "${dst}"
    dst=${src//+([A-Za-z])/..}/${dst}
    ln -s "${dst#../}" "${src}"
}

mkdir -p var/stash
mkdir -p usr/include

mv -v usr/lib/_ncurses/* usr/lib
rmdir usr/lib/_ncurses
ln -s /usr/lib usr/lib/_ncurses

rmdir --ignore-fail-on-non-empty System/Library/LaunchDaemons

#stash usr/share/gettext

rm -f "${PKG_RSLT}/Manual_${PKG_ARCH}.tgz"
tar -zcf "${PKG_RSLT}/Manual_${PKG_ARCH}.tgz" *
tar -Jcf "${PKG_RSLT}/Manual_${PKG_ARCH}.txz" *

rm -f "${PKG_RSLT}/Manual_${PKG_ARCH}.zip"
zip -qry "${PKG_RSLT}/Manual_${PKG_ARCH}.zip" *

if [[ ${PKG_ARCH} == darwin-arm ]]; then
    "${PKG_TARG}-gcc" -o "${PKG_BOOT}/usr/libexec/cydia_/godmode" "${PKG_BASE}/util/godmode.c"
    "${PKG_TARG}-gcc" -o "${PKG_BOOT}/usr/libexec/cydia_/symlink" "${PKG_BASE}/util/symlink.c"
    chmod +s "${PKG_BOOT}/usr/libexec/cydia_"/{godmode,symlink}

    cp -a bin/bash usr/libexec/cydia_
    cp -a bin/chmod usr/libexec/cydia_
    cp -a bin/chown usr/libexec/cydia_
    cp -a bin/cp usr/libexec/cydia_
    cp -a bin/df usr/libexec/cydia_
    cp -a bin/grep usr/libexec/cydia_
    cp -a bin/ln usr/libexec/cydia_
    cp -a bin/mkdir usr/libexec/cydia_
    cp -a bin/mktemp usr/libexec/cydia_
    cp -a bin/rm usr/libexec/cydia_
    cp -a bin/sed usr/libexec/cydia_
    cp -a sbin/reboot usr/libexec/cydia_
    cp -a usr/bin/basename usr/libexec/cydia_
    cp -a usr/bin/du usr/libexec/cydia_
    cp -a usr/lib/libhistory.5.2.dylib usr/libexec/cydia_
    cp -a usr/lib/libintl.8.0.2.dylib usr/libexec/cydia_
    cp -a usr/lib/libncurses.5.dylib usr/libexec/cydia_
    cp -a usr/lib/libreadline.5.2.dylib usr/libexec/cydia_

    rm -f "${PKG_RSLT}/AppTapp_${PKG_ARCH}.xml"
    find * -type l -print -o -name "terminfo" -prune | while read -r link; do
        echo "<array><string>Exec</string><string>/usr/libexec/cydia_/symlink $(readlink "${link}") /${link}</string></array>"
        rm -f "${link}"
    done >"${PKG_RSLT}/AppTapp_${PKG_ARCH}.xml"

    rm -f "${PKG_RSLT}/AppTapp_${PKG_ARCH}.zip"
    zip -qry "${PKG_RSLT}/AppTapp_${PKG_ARCH}.zip" *
fi

#rm -rf "${PKG_BOOT}"
