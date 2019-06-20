#!/usr/bin/bash
# SemaphoreCI Kernel Build Script
# Copyright (C) 2018 Raphiel Rollerscaperers (raphielscape)
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Telegram FUNCTION begin
#

cd ~
sudo install-package --update-new ccache bc bash git-core gnupg build-essential \
		zip curl make automake autogen autoconf autotools-dev libtool shtool python \
		m4 gcc libtool zlib1g-dev dash pigz

KERNEL_DIR=$SEMAPHORE_PROJECT_DIR
TELEGRAM_ID=-1001270351421
TELEGRAM=$KERNEL_DIR/telegram/telegram
TELEGRAM_TOKEN=${BOT_API_KEY}
KERN_IMG=$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb
ZIP_DIR=$HOME/AnyKernel3
CONFIG=beryllium_defconfig
COMMIT_HASH="$(git log --pretty=format:'%h' -n 1)"
CORES=$(grep -c ^processor /proc/cpuinfo)
THREAD="-j$CORES"
CROSS_COMPILE+="ccache "
CC="ccache clang"
PATH=$HOME/gcc-4.9/bin:$HOME/arm-maestro-linux-gnueabi/bin:$HOME/aosp-clang/bin:$PATH
export PATH
CROSS_COMPILE+="aarch64-linux-gnu-"
CLANG_TRIPLE="aarch64-linux-gnu-"
CROSS_COMPILE_ARM32="arm-maestro-linux-gnueabi-"
# Export
export JOBS="$(grep -c '^processor' /proc/cpuinfo)"
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER=TheFantasyGhost
export KBUILD_BUILD_HOST=CI
export CROSS_COMPILE
export CROSS_COMPILE_ARM32
export CC
export CLANG_TRIPLE
export TELEGRAM_TOKEN

# Push kernel installer to channel
function push() {
    "${TELEGRAM}" -f $zipname-signed.zip \
    -c ${TELEGRAM_ID} -t $TELEGRAM_TOKEN
}

function clone() {
  cd ~
  wget https://releases.linaro.org/components/toolchain/binaries/4.9-2017.01/aarch64-linux-gnu/gcc-linaro-4.9.4-2017.01-x86_64_aarch64-linux-gnu.tar.xz
  git clone https://github.com/RaphielGang/aosp-clang.git
  git clone https://github.com/baalajimaestro/arm-maestro-linux-gnueabi.git
  git clone https://github.com/TheFantasyGhost/AnyKernel3.git
  tar -xf gcc-linaro-4.9.4-2017.01-x86_64_aarch64-linux-gnu.tar.xz
  mv gcc-linaro-4.9.4-2017.01-x86_64_aarch64-linux-gnu gcc-4.9
  rm -rf gcc-linaro-4.9.4-2017.01-x86_64_aarch64-linux-gnu.tar.xz
  cd $KERNEL_DIR
}

clone

# Push kernel installer to channel
function push() {
    "${TELEGRAM}" -f $zipname-signed.zip \
    -c ${TELEGRAM_ID} -t $TELEGRAM_TOKEN
}

# Send the info up
function tg_channelcast() {
	"${TELEGRAM}" -c ${TELEGRAM_ID} -H \
		"$(
			for POST in "${@}"; do
				echo "${POST}"
			done
		)"
}

function tg_sendinfo() {
	curl -s "https://api.telegram.org/bot$BOT_API_KEY/sendMessage" \
		-d "parse_mode=markdown" \
		-d text="${1}" \
		-d chat_id="$TELEGRAM_ID" \
		-d "disable_web_page_preview=true"
}

# Errored prober
function finerr() {
	tg_sendinfo "$(echo -e "Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds\nbut it's error...")"
	exit 1
}

# Send sticker
function tg_sendstick() {
	curl -s -X POST "https://api.telegram.org/bot$BOT_API_KEY/sendSticker" \
		-d sticker="CAADBAAD-h8AAmSKPgABbQq3AAHi1j-PAg" \
		-d chat_id="$TELEGRAM_ID" >> /dev/null
}

# Fin prober
function fin() {
	tg_sendinfo "$(echo "Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.")"
}


cd $KERNEL_DIR

DATE=`date`
BUILD_START=$(date +"%s")

tg_sendstick
tg_channelcast "<b>Fantasy</b> kernel starting build!" \
		"Under commit <code>$(git log --pretty=format:'"%h : %s"' -1)</code>" \
		"Started on <code>$(date)</code>"

rm -rf .git


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
zipname="Fantasy-$(date +%d%m%y)-${SEMAPHORE_BUILD_NUMBER}"
ls | grep "Fantasy" | xargs rm -rf
export zipname
zip -r9 $zipname.zip * -x .git README.md zipsigner-3.0.jar
java -jar zipsigner-3.0.jar $zipname.zip $zipname-signed.zip
echo "Flashable zip generated under $ZIP_DIR."
push
cd ..
fin
# Build end