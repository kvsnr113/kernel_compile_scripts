#!/usr/bin/env bash
# Copyright ©2022 XSans02 - Modified by 113
# Kernel Build Script

HOME="$PWD"
BASE_DIR="../$PWD"
export KBUILD_BUILD_USER="kvsnr113"
export KBUILD_BUILD_HOST="projkt113"

msg(){
    echo -e "\e[1;32m$*\e[0m"
}

panel(){
    echo -e "\e[1;34m$*\e[0m"
}

panel2(){
    echo -ne "\e[1;34m$*\e[0m"
}

err(){
    echo -e "\e[1;31m$*\e[0m"
}

msg "* Checking..."
sleep 1
[[ "$GIT_TOKEN" ]] && {
    msg "(OK) Git Token"
} || {
    err "(X) GIT_TOKEN Not Found"
    exit
}
sleep 1
[[ "$TELEGRAM_TOKEN" ]] && {
    msg "(OK) Telegram Token"
} ||
    err "(X) TELEGRAM_TOKEN Not Found"
    exit
}
sleep 1
[[ "$CHANNEL_ID" ]] && {
    msg "(OK) Channel ID"
} || 
    err "(X) CHANNEL_ID Not Found"
    exit
}
sleep 1

# Clone Toolchain Source
if [[ "$1" == "weebx" ]]; then
    msg "* Use WeebX Clang..."
    wget  $(curl https://github.com/XSans02/WeebX-Clang/raw/main/WeebX-Clang-link.txt 2>/dev/null) -O "WeebX-Clang.tar.gz"
    mkdir $BASE_DIR/"$1"-clang && tar -xf WeebX-Clang.tar.gz -C $BASE_DIR/"$1"-clang && rm -rf WeebX-Clang.tar.gz
elif [[ "$1" == "azure" ]]; then
    msg "* Use Azure Clang..."
    git clone --depth=1 https://gitlab.com/Panchajanya1999/azure-clang $BASE_DIR/"$1"-clang
elif [[ "$1" == "sd" ]]; then
    msg "* Use SDClang..."
    git clone --depth=1 https://github.com/ZyCromerZ/SDClang $BASE_DIR/"$1"-clang
elif [[ "$1" == "aosp" ]]; then
    msg "* Use AOSP Clang..."
    CVER="r450784e"
    wget https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/master/clang-"$CVER".tar.gz
    mkdir $BASE_DIR/"$1"-clang && tar -xf clang-"$CVER".tar.gz -C $BASE_DIR/"$1"-clang && rm -rf clang-"$CVER".tar.gz
fi

[[ "$1" == "sd" ]] || [[ "$1" == "aosp" ]] && {
    [[ ! -d $BASE_DIR/arm32 ]] && {
        git clone --depth=1 https://github.com/XSans02/arm-linux-androideabi-4.9 $BASE_DIR/arm32
    }
    [[ ! -d $BASE_DIR/arm32 ]] && {
        git clone --depth=1 https://github.com/XSans02/aarch64-linux-android-4.9 $BASE_DIR/arm64
    }
}

AK3_DIR="$BASE_DIR/AnyKernel3"
[[ ! -d $AK3_DIR ]] && {
    msg ""
    msg "* Cloning AK3 Source..."
    git clone --depth=1 -b master https://github.com/$KBUILD_BUILD_USER/AnyKernel3
}

# environtment
KERNEL_DIR="$PWD"
KERNEL_IMG="$KERNEL_DIR/out/arch/arm64/boot/Image.gz"
KERNEL_DTBO="$KERNEL_DIR/out/arch/arm64/boot/dtbo.img"
KERNEL_DTB="$KERNEL_DIR/out/arch/arm64/boot/dtb.img"
CODENAME="vayu"
DEFCONFIG="vayu_defconfig"
CORES=$(grep -c ^processor /proc/cpuinfo)
CPU=$(lscpu | sed -nr '/Model name/ s/.*:\s*(.*) */\1/p')
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
COMMIT="$(git log --pretty=format:'%s' -1)"

# Toolchain directory
CLANG_DIR="$BASE_DIR/"$1"-clang"
GCC64_DIR="$BASE_DIR/arm64"
GCC32_DIR="$BASE_DIR/arm32"
PrefixDir="$CLANG_DIR/bin/"

# Checking toolchain source
if [[ -d "$GCC64_DIR/aarch64-linux-android" ]]; then
    ARM64=aarch64-linux-android-
else
    ARM64=aarch64-linux-gnu-
fi
if [[ -d "$GCC32_DIR/arm-linux-androideabi" ]]; then
    ARM32=arm-linux-androideabi-
else
    ARM32=arm-linux-gnueabi-
fi

# Export
export TZ="Asia/Jakarta"
export ZIP_DATE="$(TZ=Asia/Jakarta date +'%Y%m%d')"
export ZIP_DATE2="$(TZ=Asia/Jakarta date +"%H%M")"
export CURRENTDATE=$(TZ=Asia/Jakarta date +"%A, %d %b %Y, %H:%M:%S")
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_COMPILER_STRING="$(${CLANG_DIR}/bin/clang --version | head -n 1 | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"
export PATH="$CLANG_DIR/bin:$GCC64_DIR/bin:$GCC32_DIR/bin:$PATH"

# Telegram Setup
git clone --depth=1 https://github.com/XSans02/Telegram Telegram

TELEGRAM=Telegram/telegram
send_msg() {
  "${TELEGRAM}" -c "${CHANNEL_ID}" -H -D \
      "$(
          for POST in "${@}"; do
              echo "${POST}"
          done
      )"
}

send_file() {
  "${TELEGRAM}" -f "$(echo "$AK3_DIR"/*.zip)" \
  -c "${CHANNEL_ID}" -H \
      "$1"
}

send_log() {
  "${TELEGRAM}" -f "$(echo out/log.txt)" \
  -c "${CHANNEL_ID}" -H \
      "$1"
}

# Menu
while true; do
    panel ""
    panel " Menu                                                               "
    panel " ╔═════════════════════════════════════════════════════════════════╗"
    panel " ║ 1. Export defconfig to Out Dir                                  ║"
    panel " ║ 2. Start Compile With Clang                                     ║"
    panel " ║ 3. Start Compile With Clang LLVM                                ║"
    panel " ║ 4. Copy Image to Flashable Dir                                  ║"
    panel " ║ 5. Copy dtbo to Flashable Dir                                   ║"
    panel " ║ 6. Copy dtb to Flashable Dir                                    ║"
    panel " ║ 7. Make Zip                                                     ║"
    panel " ║ 8. Upload to Telegram                                           ║"
    panel " ║ 9. Upload to Gdrive                                             ║"
    panel " ║ e. Back Main Menu                                               ║"
    panel " ╚═════════════════════════════════════════════════════════════════╝"
    panel2 " Enter your choice 1-9, or press 'e' for back to Main Menu : "

    read -r menu

    # Export deconfig
    if [[ "$menu" == "1" ]]; then
        make O=out $DEFCONFIG
        msg ""
        msg "(OK) Success export $DEFCONFIG to Out Dir"
        msg ""
    fi

    # Build With Clang
    if [[ "$menu" == "2" ]]; then
        msg ""
        START=$(date +"%s")
        msg "(OK) Start Compile kernel for $CODENAME, started at $CURRENTDATE using $CPU $CORES thread"
        msg ""
        send_msg "<b>New Kernel On The Way</b>" \
                 "<b>==================================</b>" \
                 "<b>Device : </b>" \
                 "<code>* $CODENAME</code>" \
                 "<b>Branch : </b>" \
                 "<code>* $BRANCH</code>" \
                 "<b>Build Using : </b>" \
                 "<code>* $CPU $CORES thread</code>" \
                 "<b>Last Commit : </b>" \
                 "<code>* $COMMIT</code>" \
                 "<b>==================================</b>"

        # Run Build
        make -j"$CORES" O=out \
            CC=clang \
            LD=ld.lld \
            AR=llvm-ar \
            NM=llvm-nm \
            AS=llvm-as \
            STRIP=llvm-strip \
            OBJCOPY=llvm-objcopy \
            OBJDUMP=llvm-objdump \
            OBJSIZE=llvm-size \
            READELF=llvm-readelf \
            CLANG_TRIPLE=aarch64-linux-gnu- \
            CROSS_COMPILE=${ARM64} \
            CROSS_COMPILE_ARM32=${ARM32} 2>&1 | tee out/log.txt

        if ! [ -a "$KERNEL_IMG" ]; then
            err ""
            err "(X) Compile Kernel for $CODENAME failed, See buildlog to fix errors"
            err ""
            send_log "<b>Build Failed, See log to fix errors</b>"
            exit
        fi

        END=$(date +"%s")
        TOTAL_TIME=$(("$END" - "$START"))
        msg ""
        msg "(OK) Compile Kernel for $CODENAME successfully, Kernel Image in $KERNEL_IMG"
        msg "(OK) Total time elapsed: $(("$TOTAL_TIME" / 60)) Minutes, $(("$TOTAL_TIME" % 60)) Second."
        msg ""

        send_msg "<b>Build Successfully</b>" \
                 "<b>==================================</b>" \
                 "<b>Build Date : </b>" \
                 "<code>* $(date +"%A, %d %b %Y, %H:%M:%S")</code>" \
                 "<b>Build Took : </b>" \
                 "<code>* $(("$TOTAL_TIME" / 60)) Minutes, $(("$TOTAL_TIME" % 60)) Second.</code>" \
                 "<b>Compiler : </b>" \
                 "<code>* $KBUILD_COMPILER_STRING</code>" \
                 "<b>==================================</b>"
    fi

        # Build With Clang LLVM
    if [[ "$menu" == "3" ]]; then
        msg ""
        START=$(date +"%s")
        msg "(OK) Start Compile kernel for $CODENAME, started at $CURRENTDATE using $CPU $CORES thread"
        msg ""
        send_msg "<b>New Kernel On The Way</b>" \
                 "<b>==================================</b>" \
                 "<b>Device : </b>" \
                 "<code>* $CODENAME</code>" \
                 "<b>Branch : </b>" \
                 "<code>* $BRANCH</code>" \
                 "<b>Build Using : </b>" \
                 "<code>* $CPU $CORES thread</code>" \
                 "<b>Last Commit : </b>" \
                 "<code>* $COMMIT</code>" \
                 "<b>==================================</b>"

        # Run Build
        make -j"$CORES" O=out \
            CC=clang \
            LD=${PrefixDir}ld.lld \
            AR=${PrefixDir}llvm-ar \
            NM=${PrefixDir}llvm-nm \
            AS=${PrefixDir}llvm-as \
            STRIP=${PrefixDir}llvm-strip \
            OBJCOPY=${PrefixDir}llvm-objcopy \
            OBJDUMP=${PrefixDir}llvm-objdump \
            OBJSIZE=${PrefixDir}llvm-size \
            READELF=${PrefixDir}llvm-readelf \
            HOSTCC=clang \
            HOSTCXX=clang++ \
            HOSTAR=${PrefixDir}llvm-ar \
	    HOSTLD=${PrefixDir}ld.lld \
            CLANG_TRIPLE=aarch64-linux-gnu- \
            CROSS_COMPILE=${ARM64} \
            CROSS_COMPILE_ARM32=${ARM32} \
            LLVM=1 2>&1 | tee out/log.txt

        if ! [ -a "$KERNEL_IMG" ]; then
            err ""
            err "(X) Compile Kernel for $CODENAME failed, See buildlog to fix errors"
            err ""
            send_log "<b>Build Failed, See log to fix errors</b>"
            exit
        fi

        END=$(date +"%s")
        TOTAL_TIME=$(("$END" - "$START"))
        msg ""
        msg "(OK) Compile Kernel for $CODENAME successfully, Kernel Image in $KERNEL_IMG"
        msg "(OK) Total time elapsed: $(("$TOTAL_TIME" / 60)) Minutes, $(("$TOTAL_TIME" % 60)) Second."
        msg ""

        send_msg "<b>Build Successfully</b>" \
                 "<b>==================================</b>" \
                 "<b>Build Date : </b>" \
                 "<code>* $(date +"%A, %d %b %Y, %H:%M:%S")</code>" \
                 "<b>Build Took : </b>" \
                 "<code>* $(("$TOTAL_TIME" / 60)) Minutes, $(("$TOTAL_TIME" % 60)) Second.</code>" \
                 "<b>Compiler : </b>" \
                 "<code>* $KBUILD_COMPILER_STRING</code>" \
                 "<b>==================================</b>"
    fi

    # Move kernel image to flashable dir
    if [[ "$menu" == "4" ]]; then
        cp "$KERNEL_IMG" "$AK3_DIR"
        msg ""
        msg "(OK) Done moving kernel img to $AK3_DIR"
        msg ""
    fi

    # Move dtbo to flashable dir
    if [ "$menu" == "5" ]; then
        mv "$KERNEL_DTBO" "$AK3_DIR"

        msg ""
        msg "(OK) Done moving dtbo to $AK3_DIR"
        msg ""
    fi

    # Move dtb to flashable dir
    if [ "$menu" == "6" ]; then
        if [[ -f $KERNEL_DTB/${BASE_DTB_NAME}.dtb ]]; then
		mv "$KERNEL_DTB" "$AK3_DIR/dtb"
	fi
        msg ""
        msg "(OK) Done moving dtb to $AK3_DIR"
        msg ""
    fi

    # Make Zip
    if [[ "$menu" == "7" ]]; then
        cd "$AK3_DIR" || exit
        ZIP_NAME=["$ZIP_DATE"]R.Y.N-"$ZIP_DATE2".zip
        zip -r9 "$ZIP_NAME" ./*
        cd "$KERNEL_DIR" || exit

        msg ""
        msg "(OK) Done Zipping Kernel"
        msg ""
    fi

    # Upload Telegram
    if [[ "$menu" == "8" ]]; then
        send_log
        send_file "<b>md5 : </b><code>$(md5sum "$AK3_DIR/$ZIP_NAME" | cut -d' ' -f1)</code>"

        msg ""
	    msg "(OK) Done Upload to Telegram"
        msg ""
    fi

    # Upload Gdrive
    if [[ "$menu" == "9" ]]; then
        if [[ -d "/usr/sbin/gdrive" ]]; then
            gdrive upload "$AK3_DIR/$ZIP_NAME"
            send_log
            send_msg "<code>$ZIP_NAME</code>" \
                     "<b>md5 : </b><code>$(md5sum "$AK3_DIR/$ZIP_NAME" | cut -d' ' -f1)</code>" \
                     "<b>Uploaded to gdrive</b>"

            msg ""
            msg "(OK) Done Upload to Gdrive"
            msg ""
        else
            err ""
            err "Please setup your gdrive first!"
            err ""
        fi
    fi

    # Exit
    if [[ "$menu" == "e" ]]; then
        exit
    fi

done
