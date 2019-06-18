#!/usr/bin/bash
# SemaphoreCI Kernel Build Script
# Copyright (C) 2018 Raphiel Rollerscaperers (raphielscape)
# SPDX-License-Identifier: GPL-3.0-or-later

#
# begin
#

KERNEL_DIR=$(pwd)
KERN_IMG=$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb
ZIP_DIR=$HOME/Fantasy/Anykernel3
CONFIG=beryllium_defconfig
COMMIT_HASH="$(git log --pretty=format:'%h' -n 1)"
CORES=$(grep -c ^processor /proc/cpuinfo)
THREAD="-j$CORES"
CROSS_COMPILE+="ccache "
CC="ccache clang"
PATH=/home/thefantasyghost/Fantasy/gcc-linaro-4.9/bin:/home/thefantasyghost/Fantasy/arm-maestro-linux-gnueabi-master/bin:/home/thefantasyghost/Fantasy/aosp-clang-master/bin:$PATH
export PATH
CROSS_COMPILE+="aarch64-linux-gnu-"
CLANG_TRIPLE="aarch64-linux-gnu-"
CROSS_COMPILE_ARM32="arm-maestro-linux-gnueabi-"
# Export
export JOBS="$(grep -c '^processor' /proc/cpuinfo)"
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER=TheFantasyGhost
export KBUILD_BUILD_HOST=buildpc
export CROSS_COMPILE
export CROSS_COMPILE_ARM32
export CC
export CLANG_TRIPLE
# Errored prober
function finerr() {
	exit 1
}

# Fin prober
function fin() {
	exit 0
}


cd $KERNEL_DIR

DATE=`date`
BUILD_START=$(date +"%s")


make  O=out $CONFIG
make  O=out $THREAD

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))

if ! [ -f $KERN_IMG ]; then
	echo -e "Kernel compilation failed, See buildlog to fix errors"
	finerr
	exit 1
fi

cd $ZIP_DIR
cp $KERN_IMG $ZIP_DIR/zImage
zipname="Fantasy-$(date +%d%m%y)-$(echo $COMMIT_HASH)"
ls | grep "Fantasy" | xargs rm -rf
export zipname
zip -r9 $zipname.zip * -x .git README.md zipsigner-3.0.jar
java -jar zipsigner-3.0.jar $zipname.zip $zipname-signed.zip
echo "Flashable zip generated under $ZIP_DIR."
# Build end
