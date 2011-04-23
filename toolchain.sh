#!/bin/bash

# Copyright (c) 2008,2009 iphonedevlinux <iphonedevlinux@googlemail.com>
# Copyright (c) 2008, 2009 m4dm4n <m4dm4n@gmail.com>
# Updated by Denis Froschauer Jan 30, 2011
# Mar,4 2011 : added mkdir $SRC_DIR
# Mar,4 2011 : added cp files/misc/Makefile.in odcctools/misc in cctools2odcctools/extract.sh
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

# What version of the toolchain are we building?
TOOLCHAIN_VERSION="4.2"
#TOOLCHAIN_VERSION="3.1.2"

#what device are we building for?
DEVICE="iPhone_3GS"
FIRMWARE_VERSION="4.2.1"
MACOSX="MacOSX10.5"

# Manualy change this if needed
#DECRYPTION_KEY_SYSTEM="ec413e58ef2149a2c5a2669d93a4e1a9fe4d7d2f580af2b2ee55c399efc3c22250b8d27a"

# Everything is built relative to IPHONEDEV_DIR
IPHONEDEV_DIR="`pwd`"

TOOLCHAIN="${IPHONEDEV_DIR}"
[ -z $BUILD_DIR ] && BUILD_DIR="${TOOLCHAIN}/bld"
[ -z $PREFIX ] && PREFIX="${TOOLCHAIN}/pre"
[ -z $SRC_DIR ] && SRC_DIR="${TOOLCHAIN}/src"
[ -z $SYS_DIR ] && SYS_DIR="${TOOLCHAIN}/sys"




# Usage
# ======================
#
# Run these commands in order:
# 	./toolchain.sh headers
# 	./toolchain.sh firmware
# 	./toolchain.sh darwin_sources
# 	./toolchain.sh build
#	./toolchain.sh classdump (optional)
#	./toolchain.sh clean
#	OR simply run:
#	./toolchain.sh all
#
# Following environment vars control the behaviour of this script:
#
# BUILD_DIR:
#    Build the binaries (gcc, otool etc.) in this dir.
#    Default: $TOOLCHAIN/bld
#
# PREFIX:
#    Create the ./bin ./lib dir for the toolchain executables
#    under the prefix.
#    Default: $TOOLCHAIN/pre
#
# SRC_DIR:
#    Store the sources (gcc etc.) in this dir. 
#    Default: $TOOLCHAIN/src
#
# SYS_DIR:
#    Put the toolchain sys files (the iphone root system) under this dir.
#    Default: $TOOLCHAIN/sys
#
# example for these vars:
#
# BUILD_DIR="/tmp/bld" SRC_DIR="/tmp/src" PREFIX="/usr/local" ./toolchain.sh all
#
# Be warned: Use these vars carefully if you do a ./toolchain.sh rebuild. 
#            BUILD_DIR and SYS_DIR are deleted then.
#
# Actions
# ======================
#
# ./toolchain.sh all
#   Perform all stages in the order defined below. See each individual
#   stage for details.
#
# ./toolchain.sh headers
#   Extract OSX and iPhone SDK headers from the iPhone SDK image. You
#   will need to have the image available to provide to the script. This
#   is not downloaded automatically. Results extracted to
#   $IPHONEDEV_DIR/SDKs/iPhoneOS2.{version}.sdk and
#   $IPHONEDEV_DIR/SDKs/MacOSX10.5.sdk
#
# ./toolchain.sh firmware
#   Extract iPhone or iPod touch firmware located in
#   $IPHONEDEV_DIR/files/firmware/ or downloads firmware appropriate to the
#   toolchain version automatically using firmware.list. Now searches for
#   decryptions-keys and tries to extract the root-filesystem of the
#   firmware to ./files/fw/{FirmwareVersion}/system. The symlink
#   ./files/fw/current is automatically set to the extracted system.
#
# ./toolchain.sh darwin_sources
#   You will need to register at developer.apple.com or have a valid account.
#   You may specify APPLE_ID and APPLE_PASSWORD environment variables to avoid
#   prompting.
#
# ./toolchain.sh build | rebuild
#   Starts the build process decribed by saurik in
#   http://www.saurik.com/id/4. 
#   This script uses the paths $BUILD_DIR, $SRC_DIR, $PREFIX and $SYS_DIR.
#   Theses path defaults to subpaths under $IPHONEDEV_DIR/toolchain/
#
# ./toolchain.sh classdump
#   Runs classdump on a selected iPhone over SSH in order to generate useable
#   Objective-C headers for (mostly) private frameworks.

FILES_DIR="${IPHONEDEV_DIR}/files"
SDKS_DIR="${IPHONEDEV_DIR}/sdks"
TMP_DIR="${IPHONEDEV_DIR}/tmp"
MNT_DIR="${FILES_DIR}/mnt"
FW_DIR="${FILES_DIR}/firmware"

#IPHONE_SDK="iphone_sdk_*.dmg"
IPHONE_SDK="*sdk_${TOOLCHAIN_VERSION}_final.dmg"
[ -z $IPHONE_SDK_DMG ] && IPHONE_SDK_DMG="${FILES_DIR}/${IPHONE_SDK}"

# URLS
IPHONEWIKI_KEY_URL="http://www.theiphonewiki.com/wiki/index.php?title=Firmware"
DARWIN_SOURCES_DIR="$FILES_DIR/darwin_sources"

NEEDED_COMMANDS="gcc make sudo mount cpio zcat tar wget unzip gawk bison flex patch"

HERE=`pwd`

# Compare two version strings and return a string indicating whether the first version number
# is newer, older or equal to the second. This is quite dumb, but it works.
vercmp() {
	V1=`echo "$1" | sed -e 's/[^0-9]//g' | LANG=C awk '{ printf "%0.10f", "0."$0 }'`
	V2=`echo "$2" | sed -e 's/[^0-9]//g' | LANG=C awk '{ printf "%0.10f", "0."$0 }'`
	[[ $V1 > $V2 ]] && echo "newer"
	[[ $V1 == $V2 ]] && echo "equal"
	[[ $V1 < $V2 ]] && echo "older"
}

# Beautified echo commands
cecho() {
	while [[ $# > 1 ]]; do
		case $1 in
			red)	echo -n "$(tput setaf 1)";;
			green)	echo -n "$(tput setaf 2)";;
			blue)	echo -n "$(tput setaf 3)";;
			purple)	echo -n "$(tput setaf 4)";;
			cyan)	echo -n "$(tput setaf 5)";;
			grey)	echo -n "$(tput setaf 6)";;
			white)	echo -n "$(tput setaf 7)";;
			bold)	echo -n "$(tput bold)";;
			*) 	break;;
		esac
		shift
	done
	echo "$*$(tput sgr0)"
}

# Shorthand method of asking a yes or no question with a default answer
confirm() {
	local YES="Y"
	local NO="n"
	if [ "$1" == "-N" ]; then
		NO="N"
		YES="y"
		shift
	fi
	read -p "$* [${YES}/${NO}] "
	if [ "$REPLY" == "no" ] || [ "$REPLY" == "n" ] || ([ "$NO" == "N" ] && [ -z "$REPLY" ] ); then
		return 1
	fi
	if [ "$REPLY" == "yes" ] || [ "$REPLY" == "y" ] || ([ "$YES" == "Y" ] && [ -z "$REPLY" ] ); then
		return 0
	fi
}

error() {
	cecho red $*
}

message_status() {
	cecho green $*
}

message_action() {
	cecho blue $*
}

# Platform independent mount command for the DMGs used in this script
mount_dmg() {
	# Key provided, we need to decrypt the DMG first
	if [ ! -z $3 ]; then
		message_status "Decrypting `basename $1`..."
		TMP_DECRYPTED=${TMP_DIR}/`basename $1`.decrypted
		if ! vfdecrypt -i $1 -o $TMP_DECRYPTED -k $3 &> /dev/null; then
			error "Failed to decrypt `basename $1`!"
			exit 1
		fi
		local DMG="${TMP_DECRYPTED}"
	else
		local DMG="$1"
	fi
	if [ "`uname -s`" == "Darwin" ]; then
		echo "In order to extract `basename $1`, I am going to mount it."
		echo "This needs to be done as root."
		sudo hdiutil attach -mountpoint $2 $DMG
	else
		# Convert the DMG to an IMG for mounting
		TMP_IMG=${TMP_DIR}/`basename $DMG .dmg`.img
		dmg2img -v -i $DMG -o $TMP_IMG
		echo "In order to extract `basename $1`, I am going to mount it."
		echo "This needs to be done as root."
		# This is needed for 3.0 sdk and dmg2img 1.6.2
		sudo mount -t hfsplus  -o loop,offset=36864 $TMP_IMG $2
	fi
	if [ ! $? == 0 ]; then
		error "Failed to mount `basename $1`."
		exit 1
	fi
}

dmg_to_img() {
	# Key provided, we need to decrypt the DMG first
	if [ ! -z $2 ]; then
		message_status "Decrypting `basename $1`..."
		TMP_DECRYPTED=${TMP_DIR}/`basename $1`.decrypted
		if ! vfdecrypt -i $1 -o $TMP_DECRYPTED -k $2 &> /dev/null; then
			error "Failed to decrypt `basename $1`!"
			exit 1
		fi
		mv ${TMP_DECRYPTED} $1
	fi
	if [ "`uname -s`" == "Darwin" ]; then
		echo "In order to extract `basename $1`, I am going to mount it."
		echo "This needs to be done as root."
		sudo hdiutil attach -mountpoint $2 $1
	else
		# Convert the DMG to an IMG for mounting
		TMP_IMG=${TMP_DIR}/`basename $DMG .dmg`.img
		dmg2img -v -i $1 -o $TMP_IMG
		mv $TMP_IMG $1
		echo "In order to extract `basename $1`, I am going to mount it."
		echo "This needs to be done as root."
	fi
	if [ ! $? == 0 ]; then
		error "Failed to mount `basename $1`."
		exit 1
	fi
}

mount_img() {
	# This is needed for 3.0 sdk and dmg2img 1.6.2
	sudo mount -t hfsplus  -o loop,offset=36864 $1 $2
}

# Platform independent umount command for the DMGs used in this script
umount_dmg() {
	if [ "`uname -s`" == "Darwin" ]; then
		sudo hdiutil detach $MNT_DIR
	else
		# shouldn't we have a DEBUG var and only
		# delete the TMP_IMG if DEBUG is not set/true
		sudo umount -fl $MNT_DIR
	fi
	if [ ! $? == 0 ]; then
		error "Failed to unmount."
		exit 1
	fi
	[ -r $TMP_IMG ] && rm -f $TMP_IMG

}

umount_img() {
	if [ "`uname -s`" == "Darwin" ]; then
		sudo hdiutil detach $MNT_DIR
	else
		# shouldn't we have a DEBUG var and only
		# delete the TMP_IMG if DEBUG is not set/true
		sudo umount -fl $MNT_DIR
	fi
	if [ ! $? == 0 ]; then
		error "Failed to unmount."
		exit 1
	fi
}

# Takes a plist string and does a very basic lookup of a particular key value,
# given a key name and an XPath style path to the key in terms of dict entries
plist_key() {
	local PLIST_PATH="$2"
	local PLIST_KEY="$1"
	local PLIST_DATA="$3"

	cat "${PLIST_DATA}" | awk '
		/<key>.*<\/key>/ { sub(/^.*<key>/, "", $0); sub(/<\/key>.*$/, "", $0); lastKey = $0; }
		/<dict>/ { path = path lastKey "/"; }
		/<\/dict>/ { sub(/[a-zA-Z0-9]*\/$/, "", path);}
		/<((string)|(integer))>.*<\/((string)|(integer))>/ {
			if(lastKey == "'"${PLIST_KEY}"'" && path == "'"${PLIST_PATH}"'") {
				sub(/^.*<((string)|(integer))>/,"", $0);
				sub(/<\/((string)|(integer))>.*$/,"", $0);
				print $0;
			}
		}'
}

# Builds dmg2img decryption tools and vfdecrypt, which we will use later to convert dmgs to
# images, so that we can mount them.
build_tools() {
	mkdir -p $TMP_DIR

	if [ -z $(which dmg2img) ] ; then 
		message_status "Retrieving and building dmg2img 1.6.2 ..."

		cd $TMP_DIR
		if ! wget -O - http://vu1tur.eu.org/tools/download.pl?dmg2img-1.6.2.tar.gz | tar -zx; then
			error "Failed to get and extract dmg2img-1.6.2 Check errors."
			exit 1
		fi

		pushd dmg2img-1.6.2

		if ! make install; then
			error "Failed to make dmg2img-1.6.2"
			error "Make sure you have libbz2 and libssl available on your system."
			exit 1
		fi

		popd
		rm -Rf dmg2img-1.6.2
	fi
	message_status "dmg2img is ready!"

	if [ -z $(which xar) ] ; then 
		cd $TMP_DIR
		if ! wget -O - http://xar.googlecode.com/files/xar-1.5.2.tar.gz | tar -zx; then
			error "Failed to get and extract xar-1.5.2 Check errors."
			exit 1
		fi

		pushd xar-1.5.2

		if ! make install; then
			error "Failed to make xar-1.5.2"
			exit 1
		fi

		popd
		rm -Rf xar-1.5.2
	fi
	message_status "xar is ready!"

	if [ -z $(which git) ] ; then 
		cd $TMP_DIR
		if ! wget -O - http://www.kernel.org/pub/software/scm/git/git-1.7.3.tar.gz | tar -zx; then
			error "Failed to get and extract git-1.7.3 Check errors."
			exit 1
		fi

		pushd git-1.7.3

		if ! make install; then
			error "Failed to make git-1.7.3"
			exit 1
		fi

		popd
		rm -Rf git-1.7.3
	fi
	message_status "git is ready!"

	if [ -z $(which ldid) ] ; then 
		pushd ldid-1.0.476/util

		if ! make install; then
			error "Failed to make ldid-1.0.476"
			exit 1
		fi

		popd
	fi
	message_status "ldid is ready!"

	if [[ `strings /usr/bin/as | grep as_driver | wc -w` < 1 ]]; then
		cp /usr/bin/as /usr/bin/i386-redhat-linux-as
		message_status "Rename /usr/bin/as in /usr/bin/i386-redhat-linux-as"
		cp as_driver/as_driver /usr/bin/as
	fi
	message_status "as_driver installed in /usr/bin/as"
}

toolchain_extract_headers() {
	build_tools
	mkdir -p ${MNT_DIR} ${SDKS_DIR} ${TMP_DIR}

	# Make sure we don't already have these
	if [ -d "${SDKS_DIR}/iPhoneOS${TOOLCHAIN_VERSION}.sdk" ] && [ -d "${SDKS_DIR}/${MACOSX}.sdk" ]; then
		echo "SDKs seem to already be extracted."
		return
	fi

	# Look for the DMG and ask the user if is isn't findable.
	if ! [ -r $IPHONE_SDK_DMG ] ; then
		echo "I'm having trouble finding the iPhone SDK. I looked here:"
		echo $IPHONE_SDK_DMG
		if ! confirm "Do you have the SDK?"; then
			error "You will need to download the SDK before you can build the toolchain. The"
			error "required file can be obtained from: http://developer.apple.com/iphone/"
			exit 1
		fi
		echo "Please enter the full path to the dmg containing the SDK:"
		read IPHONE_SDK_DMG
		if [ ! -r $IPHONE_SDK_DMG ] ; then
			error "Sorry, I can't find the file!"
			error "You will need to download the SDK before you can build the toolchain. The"
			error "required file can be obtained from: http://developer.apple.com/iphone/"
			exit 1
		fi
	fi

	# Inform the user why we suddenly need their password
	message_status "Trying to mount the iPhone SDK dmg..."
	mount_dmg $IPHONE_SDK_DMG $MNT_DIR

	# Check the version of the SDK
	# Apple seems to apply a policy of rounding off the last component of the long version number
	# so we'll do the same here
	SDK_VERSION=$(plist_key CFBundleShortVersionString "/" "${MNT_DIR}/iPhone SDK.mpkg/Contents/version.plist" | awk '
		BEGIN { FS="." }
		{
			if(substr($4,1,1) >= 5)
				$3++
			if($3 > 0)	printf "%s.%s.%s", $1, $2, $3
			else		printf "%s.%s", $1, $2
		}')
	echo "SDK is version ${SDK_VERSION}"

	if [ "`vercmp $SDK_VERSION $TOOLCHAIN_VERSION`" == "older" ]; then
		error "We are trying to build toolchain ${TOOLCHAIN_VERSION} but this"
		error "SDK is ${SDK_VERSION}. Please download the latest SDK here:"
		error "http://developer.apple.com/iphone/"
		echo "Unmounting..."
		umount_dmg
		exit 1
	fi

	# Check which PACKAGE we have to extract. Apple does have different
	# namings for it, depending on the SDK version. 
	if [ "${TOOLCHAIN_VERSION}" == "3.1.2" ] ; then
		PACKAGE="iPhoneSDKHeadersAndLibs.pkg"
	elif [[ "`vercmp $SDK_VERSION $TOOLCHAIN_VERSION`" == "newer" ]]; then
		PACKAGE="iPhoneSDK`echo $TOOLCHAIN_VERSION | sed 's/\./_/g' `.pkg"
	else
		PACKAGE="iPhoneSDKHeadersAndLibs.pkg"
	fi

	if [ ! -r ${MNT_DIR}/Packages/$PACKAGE ]; then
		error "I tried to extract $PACKAGE but I couldn't find it!"
		echo "Unmounting..."
		umount_dmg
		exit 1
	fi

	message_status "Extracting `basename $PACKAGE`..."

	rm -fR $TMP_DIR/*

	cp ${MNT_DIR}/Packages/$PACKAGE $TMP_DIR/iphone.pkg
	cd $TMP_DIR
	xar -xf iphone.pkg Payload
	# zcat on OSX needs .Z suffix
	cat Payload | zcat | cpio -id

	# These folders are version named so the SDK version can be verified
	if [ ! -d Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS${TOOLCHAIN_VERSION}.sdk ]; then
		error "I couldn't find the folder iPhoneOS${TOOLCHAIN_VERSION}.sdk. Perhaps this is"
		error "not the right SDK dmg for toolchain ${TOOLCHAIN_VERSION}."
		exit 1
	fi

	mv -f Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS${TOOLCHAIN_VERSION}.sdk ${SDKS_DIR}

	rm -fR $TMP_DIR/*

	message_status "Extracting ${MACOSX}.pkg..."

	cp ${MNT_DIR}/Packages/${MACOSX}.pkg $TMP_DIR/macosx.pkg
	cd $TMP_DIR 
	xar -xf macosx.pkg Payload
	cat Payload | zcat | cpio -id
	mv -f SDKs/${MACOSX}.sdk ${SDKS_DIR}

	rm -fR $TMP_DIR/*

	message_status "Unmounting iPhone SDK img..."
	cd $HERE
	umount_dmg
}

toolchain_extract_firmware_old() {
	build_tools
	mkdir -p $FW_DIR $MNT_DIR $TMP_DIR

	if [ -f "${FW_DIR}/current" ] ; then
		echo "firmware seem to already be extracted."
		if ! confirm -N "extract again?"; then
			message_status "Firmware extracted to ${FW_DIR}/current"
			return
		fi
	fi

	if [ -z "$FW_FILE" ]; then
		FW_FILE=`ls ${FW_DIR}/*${TOOLCHAIN_VERSION}*.ipsw 2>/dev/null`
		if [ ! $? ] && [[ `echo ${FW_FILE} | wc -w` > 1 ]]; then
			error "I attempted to search for the correct firmware version, but"
			error "it looks like you have several ipsw files. Please specify"
			error "one like so:"
			echo -e "\texport FW_FILE=/path/to/firmware/"
			echo -e "\t./toolchain.sh firmware"
			exit 1
		fi
	fi

	# If we can't find the firmware file we try to download it from the
	# apple download urls above.
	if [ ! -r "$FW_FILE" ] ; then
		echo "I can't find the firmware image for iPhone/iPod Touch $TOOLCHAIN_VERSION."
		if ! confirm -N "Do you have it?"; then
			if confirm "Do you want me to download it?"; then
				APPLE_DL_URL=$(cat ${HERE}/firmware.list | awk '$1 ~ /'"^${FIRMWARE_VERSION}$"'/ && $2 ~ /^iPhone\(3GS\)$/ { print $3; }')
				FW_FILE=`basename "${APPLE_DL_URL}"`
				if [ ! $APPLE_DL_URL ] ; then
					error "Can't find a download url for the firmware ${FIRMWARE_VERSION} and platform ${DEVICE}."
					error "You may have to download it manually.".
					exit 1
				else 
					message_status "Downloading: $FW_FILE"
					cd $TMP_DIR
					wget -nc -c $APPLE_DL_URL
					mv $FW_FILE $FW_DIR
					FW_FILE=$FW_DIR/$FW_FILE
				fi
			fi
		else
			while [ ! -r "$FW_FILE" ]; do
				read -p "Location of firmware image: " FW_FILE
				[ ! -a $FW_FILE ] && error "File not found."
			done
		fi
	fi

	cd "$FW_DIR"

	# Sometimes the firmware download is broken. Had this problem while
	# automatically download the firmware with wget above. Is it a problem
	# of wget or does apple have any checks? Maybe we should use wget
	# with an alternative user agent

	sha1cmd=`which sha1sum`
	if [ "x$sha1cmd" != "x" ] ; then
		ff=`basename ${FW_FILE}`
		should=$(cat ${HERE}/firmware.list | \
			awk '$1 ~ /'"^${TOOLCHAIN_VERSION}$"'/ && $3 ~ /'"${ff}"'/ { print $4; }')
		sha1=$(sha1sum ${FW_FILE} | awk ' { print $1; exit; }')
		if [ "x$should" != "x" -a "x$should" != "x" ] ; then
			if [ "$sha1" == "$should" ] ; then 
				cecho green "Checksum of firmware file is valid."
			else
				cecho red "The calculated checksum of the firmware differs "
				cecho red "from the original one. One day I had a problem "
				cecho red "to download a firmware with wget. The file was "
				cecho red "broken. After trying the same download with "
				cecho red "firefox I got a valid firmware file."
				cecho red "If you encounter some problems while extracting "
				cecho red "the firmware please download the file with another "
				cecho red "user agent"
			fi
		fi
	fi

	unzip -d "${TMP_DIR}" -o "${FW_FILE}" Restore.plist

	# Retrieve information from the firmware image we downloaded so we know
	# which file to decrypt and which key to use to decrypt it
	FW_DEVICE_CLASS=$(plist_key DeviceClass "/" "${TMP_DIR}/Restore.plist")
	FW_PRODUCT_VERSION=$(plist_key ProductVersion "/" "${TMP_DIR}/Restore.plist")
	FW_BUILD_VERSION=$(plist_key ProductBuildVersion "/" "${TMP_DIR}/Restore.plist")
	FW_RESTORE_RAMDISK=$(plist_key User "/RestoreRamDisks/" "${TMP_DIR}/Restore.plist")
	FW_RESTORE_SYSTEMDISK=$(plist_key User "/SystemRestoreImages/" "${TMP_DIR}/Restore.plist")
	FW_VERSION_DIR="${FW_DIR}/${FW_PRODUCT_VERSION}_${FW_BUILD_VERSION}"
	HW_BOARD_CONFIG=$(plist_key BoardConfig "/DeviceMap/" "${TMP_DIR}/Restore.plist")

	cecho bold "Firmware Details"
	echo "Device Class: ${FW_DEVICE_CLASS}"
	echo "Product Version: ${FW_PRODUCT_VERSION}"
	echo "Build Version: ${FW_BUILD_VERSION}"
	echo "Restore RamDisk: ${FW_RESTORE_RAMDISK}"
	echo "Restore Image: ${FW_RESTORE_SYSTEMDISK}"
	echo "Board Config: ${HW_BOARD_CONFIG}"

	if [[ $FW_PRODUCT_VERSION != $FIRMWARE_VERSION ]]; then
		error "The firmware image is for ${FW_DEVICE_CLASS} version ${FW_PRODUCT_VERSION}, but we are"
		error "building toolchain version ${FIRMWARE_VERSION}. These may be incompatible."
		if ! confirm "Proceed?"; then
			error "Firmware extraction will not proceed."
			exit 1
		fi
	fi

	message_status "Unzipping `basename $FW_RESTORE_SYSTEMDISK`..."
	unzip -d "${TMP_DIR}" -o "${FW_FILE}" "${FW_RESTORE_SYSTEMDISK}"

	if [ -z "$DECRYPTION_KEY_SYSTEM" ] ; then
		echo "We need the decryption key for `basename $FW_RESTORE_SYSTEMDISK`."
		echo "I'm going to try to fetch it from $IPHONEWIKI_KEY_URL...."
		echo "Checking $DEVICE and $FIRMWARE_VERSION"

		IPHONEWIKI_KEY_URL=$( wget --quiet -O - $IPHONEWIKI_KEY_URL | awk '
		    BEGIN { IGNORECASE = 1; }
	    	/name="'${DEVICE}'/  { found_phone=1; } 
			/.*'${FIRMWARE_VERSION}'.*/ && found_phone { found_firmware=1; }
	     	/.*href=.*/ && found_firmware { while(sub(/href=|"/,"", $3));; print $3; exit;}  
		')
		
		echo "Finding intermediate URL : http://www.theiphonewiki.com$IPHONEWIKI_KEY_URL"
		DECRYPTION_KEY_SYSTEM=`wget --quiet -O - "http://www.theiphonewiki.com"$IPHONEWIKI_KEY_URL | awk '
 		    BEGIN { IGNORECASE = 1; }
			/.*VFDecrypt<\/a>.*/  { print $5;}  
		'`

		if [ ! "$DECRYPTION_KEY_SYSTEM" ] ; then
			error "Sorry, no decryption key for system partition found!"
			exit 1
		fi
		echo "Decryption Key Found : $DECRYPTION_KEY_SYSTEM"
	fi

#	message_status "Mounting ${FW_RESTORE_SYSTEMDISK}..."
#	mount_dmg "${TMP_DIR}/${FW_RESTORE_SYSTEMDISK}" "${MNT_DIR}" "${DECRYPTION_KEY_SYSTEM}"
	mv ${TMP_DIR}/${FW_RESTORE_SYSTEMDISK} ${FW_DIR}/current
	dmg_to_img ${FW_DIR}/current "${DECRYPTION_KEY_SYSTEM}"
	message_status "Firmware extracted to ${FW_DIR}/current"

#	cd "${MNT_DIR}"
#	message_status "Copying required components of the firmware..."

#	mkdir -p "${FW_VERSION_DIR}"
#	sudo cp -R -p * "${FW_VERSION_DIR}"
#	sudo chown -R `id -u`:`id -g` $FW_VERSION_DIR
#	message_status "Unmounting..."

#	cd "${HERE}"
#	umount_dmg

#	if [ -s "${FW_DIR}/current" ] ; then
#		rm "${FW_DIR}/current"
#	fi

#	ln -s "${FW_VERSION_DIR}" "${FW_DIR}/current"
#	rm "${TMP_DIR}/$FW_RESTORE_SYSTEMDISK" "${TMP_DIR}/${FW_RESTORE_SYSTEMDISK}.decrypted" $FW_SYSTEM_DMG "${TMP_DIR}/Restore.plist"
}

toolchain_extract_firmware() {
	build_tools
	message_status "Downloading and extracting firmware are no more necessary"
}

# thanks to no.name.11234 for the tip to download the darwin sources
# from http://www.opensource.apple.com/tarballs
toolchain_download_darwin_sources_sys3() {

	if [ -r "${DARWIN_SOURCES_DIR}/xnu-1228.7.58.tar.gz" ] ; then
		echo "Darwin sources seem to already be downloaded."
		if ! confirm -N "Download again?"; then
			return
		fi
	fi

	mkdir -p $DARWIN_SOURCES_DIR && cd $DARWIN_SOURCES_DIR

	# Get what we're here for
	message_status "Attempting to download tool sources..."
	wget --no-clobber --keep-session-cookies --load-cookies=cookies.tmp --input-file=${HERE}/darwin-tools.list
	message_status "Finished downloading!"
	if [ -f cookies.tmp ] ; then
		rm cookies.tmp
	fi
}

toolchain_download_darwin_sources() {
	message_status "Downloading darwin sources no more necessary"
}


toolchain_cctools() {
	local CCTOOLS_DIR="$SRC_DIR/cctools"
	local TARGET="arm-apple-darwin9"

	build_as=1
	if [ -f "${PREFIX}/bin/${TARGET}-as" ]; then
		if ! confirm -N "Build cctools again?"; then
			build_as=0
		fi
	fi

	if [ "x$build_as" == "x1" ]; then
	   download_cctools=1
	   if [ -d "${SRC_DIR}/cctools" ]; then
		if ! confirm -N "Download cctools again?"; then
			download_cctools=0
		fi
	   fi
	   if [ "x$download_cctools" == "x1" ]; then
		pushd cctools2odcctools
		if [ -d odcctools ]; then
		  if confirm "remove downloaded cctools?"; then
			rm -fr odcctools
		  fi
		fi
		./extract.sh
		mkdir -p "$SRC_DIR"
		rm -fr "${CCTOOLS_DIR}"
		cp -r odcctools "${CCTOOLS_DIR}"
		popd
	   fi

		mkdir -p "${PREFIX}"
		rm -fr "${BUILD_DIR}/cctools-iphone"
		mkdir -p "${BUILD_DIR}/cctools-iphone"
		cd "${CCTOOLS_DIR}"
		message_status "Configuring cctools-iphone..."
		cd "${BUILD_DIR}/cctools-iphone"

		CFLAGS="-m32" LDFLAGS="-m32" "${CCTOOLS_DIR}"/configure \
			--target="${TARGET}" \
			--prefix="${PREFIX}"

		make clean > /dev/null

		message_status "Building cctools-iphone..."
		cecho bold "Build progress logged to: $BUILD_DIR/cctools-iphone/make.log"
		if ! ( make &>make.log && make install &>install.log ); then
			error "Build & install failed. Check make.log and install.log"
			exit 1
		fi

# default linker is now ld64
#		mv "${PREFIX}/bin/arm-apple-darwin9-ld" "${PREFIX}/bin/arm-apple-darwin9-ld_classic"
#		ln -s "${PREFIX}/bin/arm-apple-darwin9-ld64" "${PREFIX}/bin/arm-apple-darwin9-ld"

	fi
}

toolchain_llvmgcc() {
	local GCC_DIR="$SRC_DIR/gcc"
	local TARGET="arm-apple-darwin9"
	if [ -z $(which ${TARGET}-ar) ] ; then 
		export PATH="${PREFIX}/bin":"${PATH}"
	fi


	build_gcc=1
	if [ -f "${PREFIX}/bin/${TARGET}-gcc" ]; then
		if ! confirm -N "Build llvm-gcc again?"; then
			build_gcc=0
		fi
	fi

	if [ "x$build_gcc" == "x1" ]; then
		if [ ! -d $GCC_DIR ]; then
			message_status "Checking out saurik's llvm-gcc-4.2..."
			git clone -n git://git.saurik.com/llvm-gcc-4.2 "${GCC_DIR}"
			pushd "${GCC_DIR}" && git checkout b3dd8400196ccb63fbf10fe036f9f8725b2f0a39 && popd
		else
		    if confirm -N "check update gcc ?"; then
			pushd "${GCC_DIR}"
			git pull 
			# mg; after success nail to a running version
			if ! git pull git://git.saurik.com/llvm-gcc-4.2 || ! git checkout b3dd8400196ccb63fbf10fe036f9f8725b2f0a39; then
				error "Failed to checkout saurik's llvm-gcc-4.2."
				exit 1
			fi
			popd
		    fi
		fi

		message_status "Configuring gcc-4.2-iphone..."
		mkdir -p "${BUILD_DIR}/gcc-4.2-iphone"
		cd "${BUILD_DIR}/gcc-4.2-iphone"
		"${GCC_DIR}"/configure \
			--target="${TARGET}" \
			--prefix="$PREFIX" \
			--with-sysroot="$SYS_DIR" \
			--enable-languages=c,c++,objc,obj-c++ \
			--with-as="$PREFIX"/bin/"${TARGET}"-as \
			--with-ld="$PREFIX"/bin/"${TARGET}"-ld \
			--enable-wchar_t=no \
			--with-gxx-include-dir=/usr/include/c++/4.2.1
		make clean > /dev/null
		message_status "Building gcc-4.2-iphone..."
		cecho bold "Build progress logged to: $BUILD_DIR/gcc-4.2-iphone/make.log"
		if ! ( make -j2 &>make.log && make install &>install.log ); then
			error "Build & install failed. Check make.log and install.log"
			exit 1
		fi

	fi
}

# Follows the build routine for the toolchain described by saurik here:
# www.saurik.com/id/4
#

toolchain_build_sys3() {
	#local TOOLCHAIN="${IPHONEDEV_DIR}/toolchain"
	local SYS_DIR="${TOOLCHAIN}/sys${TOOLCHAIN_VERSION}"
	local LEOPARD_SDK="${SDKS_DIR}/${MACOSX}.sdk"
	local LEOPARD_SDK_INC="${LEOPARD_SDK}/usr/include"
	local LEOPARD_SDK_LIBS="${LEOPARD_SDK}/System/Library/Frameworks"
	local IPHONE_SDK="${SDKS_DIR}/iPhoneOS${TOOLCHAIN_VERSION}.sdk"
	local IPHONE_SDK_INC="${IPHONE_SDK}/usr/include"
	local IPHONE_SDK_LIBS="${IPHONE_SDK}/System/Library/Frameworks"
	local CCTOOLS_DIR="$SRC_DIR/cctools"
	local GCC_DIR="$SRC_DIR/gcc"
	local CSU_DIR="$SRC_DIR/csu"
	export PATH="$PREFIX/bin":"${PATH}"
	local TARGET="arm-apple-darwin9"
	[ ! "`vercmp $TOOLCHAIN_VERSION 2.0`" == "newer" ] && local TARGET="arm-apple-darwin8"

	mkdir -p "${TOOLCHAIN}"
	if [ ! -d "${LEOPARD_SDK}" ] ; then
	  if [ ! -f "${SDKS_DIR}/${MACOSX}.pkg" ] ; then
		error "I couldn't find ${MACOSX}.pkg at: ${SDKS_DIR}"
		exit 1
	  else
		cd "${SDKS_DIR}"; rm -f Payload; xar -xf "${SDKS_DIR}/${MACOSX}.pkg" Payload; cat Payload | zcat | cpio -id
		# zcat on OSX needs .Z suffix
		cd "${SDKS_DIR}"; mv SDKs/${MACOSX}.sdk .; rm -fr Payload SDKs
	  fi
	fi
	if [ ! -d "${IPHONE_SDK}" ] ; then
	  if [ ! -f "${SDKS_DIR}/iPhoneSDKHeadersAndLibs.pkg" ] ; then
		error "I couldn't find iPhoneSDKHeadersAndLibs.pkg at: ${SDKS_DIR}"
		exit 1
	  else
		cd "${SDKS_DIR}"; rm -f Payload; xar -xf iPhoneSDKHeadersAndLibs.pkg Payload; cat Payload | zcat | cpio -id
		# zcat on OSX needs .Z suffix
		cd "${SDKS_DIR}"; mv "Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS${TOOLCHAIN_VERSION}.sdk" .; rm -fr Payload Platforms Examples Documentation
	  fi
	fi
	

	extract_sources=1
	if [ -d "${DARWIN_SOURCES_DIR}/xnu-1228.7.58" ] ; then
		if ! confirm -N "extract darwin sources again?"; then
			extract_sources=0
		fi
	else
		if [ ! -r "${DARWIN_SOURCES_DIR}/xnu-1228.7.58.tar.gz" ] ; then
			echo "Darwin sources seem need to be downloaded."
			toolchain_download_darwin_sources_sys3
		fi
	fi

	if [ "x$extract_sources" == "x1" ]; then
		cd "${DARWIN_SOURCES_DIR}"
		message_status "Finding and extracting archives..."
		ARCHIVES=$(find ./* -name '*.tar.gz')
		for a in $ARCHIVES; do
			basename $a .tar.gz
			tar --overwrite -xzof $a
		done

		# Permissions are being extracted along with the gzipped 
		# files. I can't seem to get tar to ignore this, and they
		# are constantly in the way so I'll use this hack.
		chmod -R 755 *
	fi

	mkdir -p "${SYS_DIR}"
	cd "${SYS_DIR}"

	if [ ! -d "${FW_DIR}/firmware${TOOLCHAIN_VERSION}" ] ; then
	  if [ ! -f "${FW_DIR}/firmware${TOOLCHAIN_VERSION}.tgz" ] ; then
		error "I couldn't find an iPhone filesystem at: ${FW_DIR}/firmware${TOOLCHAIN_VERSION}.tgz"
		exit 1
	  else
		mkdir -p "${FW_DIR}/firmware${TOOLCHAIN_VERSION}"; cd "${FW_DIR}/firmware${TOOLCHAIN_VERSION}"; tar xzvf ../"firmware${TOOLCHAIN_VERSION}.tgz"
	  fi
	fi

	#mount_img "${FW_DIR}/current" "${MNT_DIR}"
	local MNT_FW_DIR="${FW_DIR}/firmware${TOOLCHAIN_VERSION}"

	cp_fw=1
	if [ -d $SYS_DIR ] && [[ `ls -A $SYS_DIR | wc -w` > 0 ]]; then
		echo "It looks like the iPhone filesystem has already been copied."
		if ! confirm -N "Copy again?"; then
			cp_fw=0
		fi
	fi

	if [ "x$cp_fw" == "x1" ]; then
		message_status "Copying required iPhone filesystem components..."
        	mkdir -p "$SYS_DIR/System/Library"
		cp -R -p ${MNT_FW_DIR}/usr "$SYS_DIR"
		cp -R -p ${MNT_FW_DIR}/System/Library/Frameworks "$SYS_DIR/System/Library"
		cp -R -p ${MNT_FW_DIR}/System/Library/PrivateFrameworks "$SYS_DIR/System/Library"
	fi

	#umount_img "${FW_DIR}/current"

	# Presently working here and below
	copy_headers=1
	if [ -d "${SYS_DIR}/usr/include" ] ; then
		if ! confirm -N "copy headers again?"; then
			copy_headers=0
		fi
	fi

	if [ "x$copy_headers" == "x1" ]; then
	message_status "Copying SDK headers..."
	echo "Leopard"
	mkdir -p "$SYS_DIR/usr/lib"
	cp -R -p "${LEOPARD_SDK_INC}" ${SYS_DIR}/usr/
	cd ${SYS_DIR}/usr/include
	ln -sf . System

	cp -R -pf "${IPHONE_SDK_INC}"/* .
	cp -R -pf "${DARWIN_SOURCES_DIR}"/xnu-1228.7.58/osfmk/* .
	cp -R -pf "${DARWIN_SOURCES_DIR}"/xnu-1228.7.58/bsd/* . 

	echo "mach"
	cp -R -pf "${DARWIN_SOURCES_DIR}"/cctools-*/include/mach .
	cp -R -pf "${DARWIN_SOURCES_DIR}"/cctools-*/include/mach-o .
	cp -R -pf "${IPHONE_SDK_INC}"/mach-o/dyld.h mach-o

	cp -R -pf "${LEOPARD_SDK_INC}"/mach/machine mach
	cp -R -pf "${LEOPARD_SDK_INC}"/mach/machine.h mach
	cp -R -pf "${LEOPARD_SDK_INC}"/machine .
	cp -R -pf "${IPHONE_SDK_INC}"/machine .

	cp -R -pf "${IPHONE_SDK_INC}"/sys/cdefs.h sys
	cp -R -pf "${LEOPARD_SDK_INC}"/sys/dtrace.h sys

	cp -R -pf "${LEOPARD_SDK_LIBS}"/Kernel.framework/Versions/A/Headers/machine/disklabel.h machine
	cp -R -pf "${DARWIN_SOURCES_DIR}"/configd-*/dnsinfo/dnsinfo.h .
	cp -R -p "${DARWIN_SOURCES_DIR}"/Libc-*/include/kvm.h .
	cp -R -p "${DARWIN_SOURCES_DIR}"/launchd-*/launchd/src/*.h .

	cp -R -p i386/disklabel.h arm
	cp -R -p mach/i386/machine_types.defs mach/arm

	mkdir -p Kernel
	echo "libsa"
	cp -R -p "${DARWIN_SOURCES_DIR}"/xnu-1228.3.13/libsa/libsa Kernel

	mkdir -p Security
	echo "libsecurity"
	cp -R -p "${DARWIN_SOURCES_DIR}"/libsecurity_authorization-*/lib/*.h Security
	cp -R -p "${DARWIN_SOURCES_DIR}"/libsecurity_cdsa_client-*/lib/*.h Security
	cp -R -p "${DARWIN_SOURCES_DIR}"/libsecurity_cdsa_utilities-*/lib/*.h Security
	cp -R -p "${DARWIN_SOURCES_DIR}"/libsecurity_cms-*/lib/*.h Security
	cp -R -p "${DARWIN_SOURCES_DIR}"/libsecurity_codesigning-*/lib/*.h Security
	cp -R -p "${DARWIN_SOURCES_DIR}"/libsecurity_cssm-*/lib/*.h Security
	cp -R -p "${DARWIN_SOURCES_DIR}"/libsecurity_keychain-*/lib/*.h Security
	cp -R -p "${DARWIN_SOURCES_DIR}"/libsecurity_mds-*/lib/*.h Security
	cp -R -p "${DARWIN_SOURCES_DIR}"/libsecurity_ssl-*/lib/*.h Security
	cp -R -p "${DARWIN_SOURCES_DIR}"/libsecurity_utilities-*/lib/*.h Security
	cp -R -p "${DARWIN_SOURCES_DIR}"/libsecurityd-*/lib/*.h Security

	mkdir -p DiskArbitration
	echo "DiskArbitration"
	cp -R -p "${DARWIN_SOURCES_DIR}"/DiskArbitration-*/DiskArbitration/*.h DiskArbitration

	echo "iokit"
	cp -R -p "${DARWIN_SOURCES_DIR}"/xnu-*/iokit/IOKit .
	cp -R -p "${DARWIN_SOURCES_DIR}"/IOKitUser-*/*.h IOKit

	cp -R -p "${DARWIN_SOURCES_DIR}"/IOGraphics-*/IOGraphicsFamily/IOKit/graphics IOKit
	cp -R -p "${DARWIN_SOURCES_DIR}"/IOHIDFamily-*/IOHIDSystem/IOKit/hidsystem IOKit

	for proj in kext ps pwr_mgt; do
		mkdir -p IOKit/"${proj}"
		cp -R -p "${DARWIN_SOURCES_DIR}"/IOKitUser-*/"${proj}".subproj/*.h IOKit/"${proj}"
	done

	ln -s IOKit/kext/bootfiles.h .

	mkdir -p IOKit/storage
	cp -R -p "${DARWIN_SOURCES_DIR}"/IOStorageFamily-*/*.h IOKit/storage
	cp -R -p "${DARWIN_SOURCES_DIR}"/IOCDStorageFamily-*/*.h IOKit/storage
	cp -R -p "${DARWIN_SOURCES_DIR}"/IODVDStorageFamily-*/*.h IOKit/storage

	mkdir DirectoryService
	cp -R -p "${DARWIN_SOURCES_DIR}"/DirectoryService-*/APIFramework/*.h DirectoryService

	mkdir DirectoryServiceCore
	cp -R -p "${DARWIN_SOURCES_DIR}"/DirectoryService-*/CoreFramework/Private/*.h DirectoryServiceCore
	cp -R -p "${DARWIN_SOURCES_DIR}"/DirectoryService-*/CoreFramework/Public/*.h DirectoryServiceCore 

	mkdir -p SystemConfiguration
	echo "configd"
	cp -R -p "${DARWIN_SOURCES_DIR}"/configd-*/SystemConfiguration.fproj/*.h SystemConfiguration

	echo "CoreFoundation"
	mkdir CoreFoundation
	cp -R -p "${LEOPARD_SDK_LIBS}"/CoreFoundation.framework/Versions/A/Headers/* CoreFoundation
	cp -R -pf "${DARWIN_SOURCES_DIR}"/CF-*/*.h CoreFoundation
	cp -R -pf "${IPHONE_SDK_LIBS}"/CoreFoundation.framework/Headers/* CoreFoundation

	for framework in AudioToolbox AudioUnit CoreAudio QuartzCore Foundation; do
		echo $framework
		mkdir -p $framework
		cp -R -p "${LEOPARD_SDK_LIBS}"/"${framework}".framework/Versions/?/Headers/* "${framework}"
		cp -R -pf "${IPHONE_SDK_LIBS}"/"${framework}".framework/Headers/* "${framework}"
	done

	for framework in UIKit AddressBook CoreLocation OpenGLES; do
		echo $framework
		mkdir -p $framework
		cp -R -pf "${IPHONE_SDK_LIBS}"/"${framework}".framework/Headers/* "${framework}"
	done

	for framework in AppKit Cocoa CoreData CoreVideo JavaScriptCore OpenGL WebKit; do
		echo $framework
		mkdir -p $framework
		cp -R -p "${LEOPARD_SDK_LIBS}"/"${framework}".framework/Versions/?/Headers/* $framework
	done
	
	echo "Application Services"
	mkdir -p ApplicationServices
	cp -R -p "${LEOPARD_SDK_LIBS}"/ApplicationServices.framework/Versions/A/Headers/* ApplicationServices
	for service in "${LEOPARD_SDK_LIBS}"/ApplicationServices.framework/Versions/A/Frameworks/*.framework; do
		echo -e "\t$(basename $service .framework)"
		mkdir -p "$(basename $service .framework)"
		cp -R -p $service/Versions/A/Headers/* "$(basename $service .framework)"
	done

	echo "Core Services"
	mkdir -p CoreServices
	cp -R -p "${LEOPARD_SDK_LIBS}"/CoreServices.framework/Versions/A/Headers/* CoreServices
	for service in "${LEOPARD_SDK_LIBS}"/CoreServices.framework/Versions/A/Frameworks/*.framework; do
		mkdir -p "$(basename $service .framework)"
		cp -R -p $service/Versions/A/Headers/* "$(basename $service .framework)"
	done

	#	DFR
	for framework in CFNetwork; do
		echo $framework
		mkdir -p $framework
		cp -R -pf "${IPHONE_SDK_LIBS}"/"${framework}".framework/Headers/* "${framework}"
	done

	#	DFR stdarg.h float.h

#	.... TODO

	mkdir WebCore
	echo "WebCore"
	cp -R -p "${DARWIN_SOURCES_DIR}"/WebCore-*/bindings/objc/*.h WebCore
	cp -R -p "${DARWIN_SOURCES_DIR}"/WebCore-*/bridge/mac/*.h WebCore 
	for subdir in css dom editing history html loader page platform{,/{graphics,text}} rendering; do
		cp -R -p "${DARWIN_SOURCES_DIR}"/WebCore-*/"${subdir}"/*.h WebCore
	done

	cp -R -p "${DARWIN_SOURCES_DIR}"/WebCore-*/css/CSSPropertyNames.in WebCore
	(cd WebCore; perl "${DARWIN_SOURCES_DIR}"/WebCore-*/css/makeprop.pl)

	mkdir kjs
	cp -R -p "${DARWIN_SOURCES_DIR}"/JavaScriptCore-*/kjs/*.h kjs

	mkdir -p wtf/unicode/icu
	cp -R -p "${DARWIN_SOURCES_DIR}"/JavaScriptCore-*/wtf/*.h wtf
	cp -R -p "${DARWIN_SOURCES_DIR}"/JavaScriptCore-*/wtf/unicode/*.h wtf/unicode
	cp -R -p "${DARWIN_SOURCES_DIR}"/JavaScriptCore-*/wtf/unicode/icu/*.h wtf/unicode/icu

	mkdir unicode
	cp -R -p "${DARWIN_SOURCES_DIR}"/JavaScriptCore-*/icu/unicode/*.h unicode
	
	cd "$SYS_DIR"
	ln -sf gcc/darwin/4.0/stdint.h usr/include
	ln -sf libstdc++.6.dylib usr/lib/libstdc++.dylib

	message_status "Applying patches..."

	if [ ! -r "${HERE}/patches/include.diff" ]; then
		error "Missing include.diff! This file is required to merge the OSX and iPhone SDKs."
		exit 1
	fi

	# patches/include.diff is a modified version the telesphoreo patches to support iPhone 3.0
	# Some patches could fail if you rerun (rebuild) ./toolchain.sh build

	#wget -qO- http://svn.telesphoreo.org/trunk/tool/include.diff | patch -p3 
	pushd "${SYS_DIR}/usr/include"
	patch -p3 -l -N < "${HERE}/patches/include.diff"

	#wget -qO arm/locks.h http://svn.telesphoreo.org/trunk/tool/patches/locks.h 
	svn cat http://svn.telesphoreo.org/trunk/tool/patches/locks.h@679 > arm/locks.h


	mkdir GraphicsServices
	cd GraphicsServices
	svn cat  http://svn.telesphoreo.org/trunk/tool/patches/GraphicsServices.h@357 > GraphicsServices.h

	popd
	fi

	# Changed some of the below commands from sudo; don't know why they were like that
	csu=1
	if [ -d "${CSU_DIR}" ] ; then
		if ! confirm -N "Checking out iphone-dev again?"; then
			csu=0
		fi
	fi

	if [ "x$csu" == "x1" ]; then
	message_status "Checking out iphone-dev repo..."
	mkdir -p "${CSU_DIR}"
	cd "${CSU_DIR}"

	if [ -d "${CSU_DIR}/.svn" ]; then
		echo "csu seems to be checked out."
		if confirm -N "checkout again?"; then
			svn co http://iphone-dev.googlecode.com/svn/trunk/csu .
		fi
	else
		svn co http://iphone-dev.googlecode.com/svn/trunk/csu .
	fi

	cp -R -p *.o "$SYS_DIR/usr/lib"
	cp -H -p "$IPHONE_SDK/usr/lib/libc.dylib" "$SYS_DIR/usr/lib/"
	cd "$SYS_DIR/usr/lib"
	chmod 644 *.o
	cp -R -pf crt1.o crt1.10.5.o
	cp -R -pf dylib1.o dylib1.10.5.o
	fi

	mkdir -p "$SYS_DIR"/"$(dirname $PREFIX)"
	ln -sf "$PREFIX" "$SYS_DIR"/"$(dirname $PREFIX)"


#	Copying Frameworks
#pushd sdks/iPhoneOS4.2.sdk/System/Library/Frameworks
#for i in *; do x=`basename $i '.framework'`; cp $i/$x "$SYS_DIR/System/Library/Frameworks/$i/$x"; done
#popd
#pushd sdks/iPhoneOS4.2.sdk/usr/lib
#cp libSystem* "${SYS_DIR}/usr/lib"
#cp libobjc* "${SYS_DIR}/usr/lib"
}


toolchain_sys() {
	#local TOOLCHAIN="${IPHONEDEV_DIR}/toolchain"
	local IPHONE_SDK="${SDKS_DIR}/iPhoneOS${TOOLCHAIN_VERSION}.sdk"
	local IPHONE_SDK_INC="${IPHONE_SDK}/usr/include"
	local IPHONE_SDK_LIBS="${IPHONE_SDK}/System/Library/Frameworks"
	local TARGET="arm-apple-darwin9"
	[ ! "`vercmp $TOOLCHAIN_VERSION 2.0`" == "newer" ] && local TARGET="arm-apple-darwin8"

	mkdir -p "${TOOLCHAIN}"
	mkdir -p "${SYS_DIR}"

	copy_headers=1
	if [ -d "${SYS_DIR}/usr/include" ] ; then
		if ! confirm -N "copy headers again?"; then
			copy_headers=0
		fi
	fi

	if [ "x$copy_headers" == "x1" ]; then
	        rm -fr "${SYS_DIR}"
	        mkdir -p "${SYS_DIR}"
		message_status "Copying System and usr from iPhoneOS${TOOLCHAIN_VERSION}.sdk"
		if [ -f "${IPHONE_SDK}.tgz" ] ; then
		  rm -fr "$IPHONE_SDK"
		  cd "${SDKS_DIR}"; tar xzvf iPhoneOS${TOOLCHAIN_VERSION}.sdk.tgz
	  	elif [ ! -f "${SDKS_DIR}/iPhoneSDK4_2.pkg" ] ; then
		  error "I couldn't find iPhoneSDK4_2.pkg at: ${SDKS_DIR}"
		  exit 1
	  	else
		  cd "${SDKS_DIR}"; rm -f Payload; xar -xf "${SDKS_DIR}/iPhoneSDK4_2.pkg" Payload; cat Payload | zcat | cpio -id
		  # zcat on OSX needs .Z suffix
		  cd "${SDKS_DIR}"; mv Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS${TOOLCHAIN_VERSION}.sdk .; rm -fr Platforms
		fi

                pushd "${IPHONE_SDK}"
		cp -R -pf System "${SYS_DIR}"
		cp -R -pf usr "${SYS_DIR}"
		popd

		message_status "Copying Frameworks headers from iPhoneOS${TOOLCHAIN_VERSION}.sdk"
		pushd "${IPHONE_SDK_LIBS}"
		for i in *.framework
		do
			f=`basename $i .framework`
			echo $f
			mkdir -p ${SYS_DIR}/usr/include/$f
			cp -Rf -p $i/Headers/* ${SYS_DIR}/usr/include/$f/
		done
		popd
	fi

	mkdir -p "$SYS_DIR"/"$(dirname $PREFIX)"
	ln -sf "$PREFIX" "$SYS_DIR"/"$(dirname $PREFIX)"

}

class_dump() {

	local IPHONE_SDK_LIBS="${SDKS_DIR}/iPhoneOS${TOOLCHAIN_VERSION}.sdk/System/Library"
	mkdir -p "${TMP_DIR}"

	if [ -z $IPHONE_IP ]; then
		echo "This step will extract Objective-C headers from the iPhone frameworks."
		echo "To do this, you will need SSH access to an iPhone with class-dump"
		echo "installed, which can be done through Cydia."
		read -p "What is your iPhone's IP address? " IPHONE_IP
		[ -z $IPHONE_IP ] && exit 1
	fi
	
	message_status "Selecting required SDK components..."
	[ -d "${SDKS_DIR}/iPhoneOS${TOOLCHAIN_VERSION}.sdk" ] || toolchain_extract_headers
	for type in PrivateFrameworks; do
		for folder in `find ${IPHONE_SDK_LIBS}/${type} -name *.framework`; do
			framework=`basename "${folder}" .framework`
			mkdir -p "${TMP_DIR}/Frameworks/${framework}"
			cp "${folder}/${framework}" "${TMP_DIR}/Frameworks/${framework}/"
		done
	done
	
	message_status "Copying frameworks to iPhone (${IPHONE_IP})..."
	echo "rm -Rf /tmp/Frameworks" | ssh root@$IPHONE_IP
	if ! scp -r "${TMP_DIR}/Frameworks" root@$IPHONE_IP:/tmp/; then
		error "Failed to copy frameworks to iPhone. Check the connection."
		exit 1
	fi
	rm -Rf "${TMP_DIR}/Frameworks"
	
	message_status "Class dumping as root@$IPHONE_IP..."
	ssh root@$IPHONE_IP <<'COMMAND'
		if [ -z `which class-dump` ]; then
			echo "It doesn't look like class-dump is installed. Would you like me"
			read -p "to try to install it (Y/n)? "
			([ "$REPLY" == "n" ] || [ "$REPLY" == "no" ]) && exit 1
			if [ -z `which apt-get` ]; then
				echo "I can't install class-dump without Cydia."
				exit 1
			fi
			apt-get install class-dump
		fi
		
		for folder in /tmp/Frameworks/*; do
			framework=`basename $folder`
			echo $framework
			pushd $folder > /dev/null
			if [ -r "$folder/$framework" ]; then
				class-dump -H $folder/$framework &> /dev/null
				rm -f "$folder/$framework"
			fi
			popd > /dev/null
		done
		exit 0
COMMAND
	if [ $? ]; then
		error "Failed to export iPhone frameworks."
		exit 1
	fi
	
	message_status "Framework headers exported. Copying..."
	scp -r root@$IPHONE_IP:/tmp/Frameworks  "${TMP_DIR}"
}

store_src() {
	File=/tmp/toolchain4-src.tar.bzip2
	message_action "Store toolchain source"
	tar cjf $File as_driver blocks cctools2odcctools/ChangeLog.odcctools cctools2odcctools/extract.sh cctools2odcctools/patches cctools2odcctools/files *.list GenericMakefileForApps4 ldid-1.0.476 patches toolchain.sh
	message_status "Toolchain source stored in $File"
}

store_dist() {
	File=/tmp/sys42.tar.bzip2
	message_action "Making $File"
	tar cjf $File toolchain/sys
	File=/tmp/odcctools-782.tar.bzip2
	message_action "Making $File"
	tar cjf $File toolchain/pre
}

check_environment() {
	[ $TOOLCHAIN_CHECKED ] && return
	message_action "Preparing the environment"
	cecho bold "Toolchain version: ${TOOLCHAIN_VERSION}"
	cecho bold "Building in: ${IPHONEDEV_DIR}"
	if [[ "`vercmp $TOOLCHAIN_VERSION 2.0`" == "older" ]]; then
		error "The toolchain builder is only capable of building toolchains targeting"
		error "iPhone SDK >=2.0. Sorry."
		exit 1
	fi
	
	# Check for required commands
	local command
	local missing
	for c in $NEEDED_COMMANDS ; do
		if [ -z $(which $c) ] ; then 
			missing="$missing $c"
		fi
	done
	if [ "$missing" != "" ] ; then
		error "The following commands are missing:$missing"
		error "You may need to install additional software for them using your package manager."
		exit 1
	fi
	
	# Performs a check for objective-c extensions to gcc
	if [ ! -z "`LANG=C gcc --help=objc 2>&1 | grep \"warning: unrecognized argument to --help\"`" ]; then
		error "GCC does not appear to support Objective-C."
		error "You may need to install support, for example the \"gobjc\" package in debian."
		exit
	fi
	
	message_status "Environment is ready"
}

case $1 in
	all)
		check_environment
		export TOOLCHAIN_CHECKED=1
		( ./toolchain.sh headers && \
		  ./toolchain.sh darwin_sources && \
		  ./toolchain.sh firmware && 
		  ./toolchain.sh cctools && 
		  ./toolchain.sh llvmgcc && 
		  ./toolchain.sh build ) || exit 1
		
		confirm "Do you want to clean up the source files used to build the toolchain?" && ./toolchain.sh clean
		message_action "All stages completed. The toolchain is ready."
		unset TOOLCHAIN_CHECKED
		;;
		
	headers)
		check_environment
		message_action "Getting the header files..."
		toolchain_extract_headers
		message_action "Headers extracted."
		;;

	darwin_sources)
		check_environment
		toolchain_download_darwin_sources
		message_action "Darwin sources retrieved."
		;;

	firmware)
		check_environment
		message_action "Extracting firmware files..."
		toolchain_extract_firmware
		message_action "Firmware extracted."
		;;

	cctools)
		check_environment
		message_action "Building cctools..."
		toolchain_cctools
		message_action "cctools build."
		;;

	llvmgcc)
		check_environment
		message_action "Building llvmgcc..."
		toolchain_llvmgcc
		message_action "llvmgcc build."
		;;

	build313)
		check_environment
		message_action "Building the sys3.1.3 Headers and Libraries..."
		TOOLCHAIN_VERSION=3.1.3
		toolchain_build_sys3
		message_action "sys3.1.3 folder built!"
		;;
	
	buildsys)
		check_environment
		message_action "Building the sys Headers and Libraries..."
	        [ -d "${SYS_DIR}" ] && rm -Rf "${SYS_DIR}"
		toolchain_sys
		message_action "SYS folder built!"
		;;
	
	build|rebuild)
		check_environment
		message_action "Building the toolchain..."
		if [ "$1" == "rebuild" ]; then
			message_action "rebuilding..."
			[ -d "${SYS_DIR}" ] && rm -Rf "${SYS_DIR}"
			[ -d "${BUILD_DIR}" ] && rm -Rf "${BUILD_DIR}"
		fi 
#		toolchain_build
		toolchain_sys
		message_action "It seems like the toolchain built!"
		;;
	
	xar)
		check_environment
		message_action "Preparing to make xar..."
		download_xar=1
		if [ -f xar-1.5.2.tar.gz ] ; then
		  if ! confirm -N "Download xar again?"; then
		        download_xar=0
		  fi
		fi
	        if [ "x$download_xar" == "x1" ]; then
		  wget -N http://xar.googlecode.com/files/xar-1.5.2.tar.gz
		fi
		extract_xar=1
		if [ -d xar-1.5.2 ] ; then
		  if ! confirm -N "Extract xar again?"; then
		        extract_xar=0
		  fi
		fi
	        if [ "x$extract_xar" == "x1" ]; then
		  tar xzf xar-1.5.2.tar.gz
		fi
		cd xar-1.5.2
		if ! (./configure) ; then
			error "Failed to configre xar-1.5.2, you need to install libxml2-dev"
			exit 1
                fi

		if ! (make && sudo make install); then
			error "Failed to make xar-1.5.2"
			exit 1
		fi
		message_action "xar built."
		;;
	ldid)
		check_environment
		message_action "Preparing to make ldid..."
		download_ldid=1
		if [ -f  ldid-1.0.610.tgz ] ; then
		  if ! confirm -N "Download ldid again?"; then
		        download_ldid=0
		  fi
		fi
	        if [ "x$download_ldid" == "x1" ]; then
		  wget -N http://svn.telesphoreo.org/trunk/data/ldid/ldid-1.0.610.tgz
		fi
		extract_ldid=1
		if [ -d  ldid-1.0.610 ] ; then
		  if ! confirm -N "Extract ldid again?"; then
		        extract_ldid=0
		  fi
		fi
	        if [ "x$extract_ldid" == "x1" ]; then
		  tar xzf ldid-1.0.610.tgz
		fi
		cd ldid-1.0.610
		g++ -I . -o util/ldid{,.cpp} -x c util/{lookup2,sha1}.c
		cp -a util/ldid ${TOOLCHAIN}/pre/bin/
		message_action "ldid built."
		;;

	classdump)
		check_environment
		message_action "Preparing to classdump..."
		class_dump
		message_action "Copy completed."
		;;

	archive)
		store_src
		store_dist
		;;

	clean)
		message_status "Cleaning up..."
		
		for file in ${FW_DIR}/*; do
			[ -d "${file}" ] && rm -Rf "${file}"
		done
#		rm -f "${FW_DIR}/current"	
		rm -Rf "${MNT_DIR}"
		rm -Rf "${DARWIN_SOURCES_DIR}"
		rm -Rf "${SDKS_DIR}"
		rm -Rf "${TMP_DIR}"
		rm -Rf "${SRC_DIR}"
		rm -Rf "${BUILD_DIR}"
		[ -r $IPHONE_SDK_DMG ] && confirm -N "Do you want me to remove the SDK dmg?" && rm "${IPHONE_SDK_DMG}"
		if confirm -N "Do you want me to remove the firmware image(s)?"; then
			for fw in $FW_DIR/*.ipsw; do rm $fw; done
		fi
		;;

	*)
		# Shows usage information to the user
		BOLD=$(tput bold)
		ENDF=$(tput sgr0)
		echo	"toolchain.sh <action>"
		echo
		echo	"    ${BOLD}all${ENDF}"
		echo -e "    \tPerform all steps in order: headers, darwin_sources,"
		echo -e "    \tfirmware, build and clean."
		echo
		echo	"    ${BOLD}headers${ENDF}"
		echo -e "    \tExtract headers from an iPhone SDK dmg provided by"
		echo -e "    \tthe user in <toolchain>/files/<sdk>.dmg."
		echo
		echo	"    ${BOLD}darwin_sources${ENDF}"
		echo -e "    \tRetrieve required Apple OSS components using a valid"
		echo -e "    \tApple ID and password."
		echo
		echo	"    ${BOLD}firmware${ENDF}"
		echo -e "    \tDownload (optional) and extract iPhone an firmware"
		echo -e "    \timage for the specified toolchain version."
		echo
		echo	"    ${BOLD}build${ENDF}"
		echo -e "    \tAcquire and build the toolchain sources."
		echo
		echo	"    ${BOLD}build313${ENDF}"
		echo -e "    \tAcquire and build the sys3.1.3 Headers & Libraries."
		echo
		echo	"    ${BOLD}buildsys${ENDF}"
		echo -e "    \tAcquire and build the sys Headers & Libraries."
		echo
		echo	"    ${BOLD}cctools${ENDF}"
		echo -e "    \tAcquire and build cctools."
		echo
		echo	"    ${BOLD}llvmgcc${ENDF}"
		echo -e "    \tAcquire and build llvmgcc."
		echo
		echo	"    ${BOLD}ldid${ENDF}"
		echo -e "    \tAcquire and build ldid."
		echo
		echo	"    ${BOLD}classdump${ENDF}"
		echo -e "    \tGenerates Objective-C headers using public and private"
		echo -e "    \tframeworks retrieved from an iPhone."
		echo
		echo	"    ${BOLD}clean${ENDF}"
		echo -e "    \tRemove source files, extracted dmgs and ipsws and"
		echo -e "    \ttemporary files, leaving only the compiled toolchain"
		echo -e "    \tand headers."
		;;
esac
