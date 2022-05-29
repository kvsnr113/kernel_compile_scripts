#!/usr/bin/env bash
# Copyright ©2022 XSans02 - Modified by 113
# Kernel Build Script

KERNEL_DIR="$PWD"
cd ..
BASE_DIR="$PWD"
cd $KERNEL_DIR
TOKEN="5382711200:AAFp0g3MrphAUgylIq8ynMAbfeOys8lzWTI"
CHATID="-1001586260532"

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
[[ "$TOKEN" ]] && {
    msg "(OK) Token"
} || {
    err "(X) TOKEN Not Found"
    exit
}
sleep 1
[[ "$CHATID" ]] && {
    msg "(OK) Chat ID"
} || {
    err "(X) CHAT_ID Not Found"
    exit
}
sleep 1

if [[ "$1" == "weebx" ]]; then
    msg "* Use WeebX Clang..."
    [[ ! -d $BASE_DIR//"$1"-clang ]] && {
        wget  $(curl https://github.com/XSans02/WeebX-Clang/raw/main/WeebX-Clang-link.txt 2>/dev/null) -O "WeebX-Clang.tar.gz"
        mkdir $BASE_DIR/"$1"-clang && tar -xf WeebX-Clang.tar.gz -C $BASE_DIR/"$1"-clang && rm -rf WeebX-Clang.tar.gz
    }
elif [[ "$1" == "azure" ]]; then
    msg "* Use Azure Clang..."
    [[ ! -d $BASE_DIR//"$1"-clang ]] && {
        git clone --depth=1 https://gitlab.com/Panchajanya1999/azure-clang $BASE_DIR/"$1"-clang
    }
elif [[ "$1" == "sd" ]]; then
    msg "* Use SDClang..."
    [[ ! -d $BASE_DIR//"$1"-clang ]] && {
        git clone --depth=1 https://github.com/ZyCromerZ/SDClang $BASE_DIR/"$1"-clang
    }
elif [[ "$1" == "aosp" ]]; then
    msg "* Use AOSP Clang..."
    [[ ! -d $BASE_DIR//"$1"-clang ]] && {
        CVER="r450784e"
        wget https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/master/clang-"$CVER".tar.gz
        mkdir $BASE_DIR/"$1"-clang && tar -xf clang-"$CVER".tar.gz -C $BASE_DIR/"$1"-clang && rm -rf clang-"$CVER".tar.gz
    }
fi

[[ "$1" == "sd" ]] || [[ "$1" == "aosp" ]] && {
    [[ ! -d $BASE_DIR/arm32 ]] && {
        git clone --depth=1 https://github.com/XSans02/arm-linux-androideabi-4.9 $BASE_DIR/arm32
    }
    [[ ! -d $BASE_DIR/arm64 ]] && {
        git clone --depth=1 https://github.com/XSans02/aarch64-linux-android-4.9 $BASE_DIR/arm64
    }
    ARM64=aarch64-linux-android-
    ARM32=arm-linux-androideabi-
} || {
    ARM64=aarch64-linux-gnu-
    ARM32=arm-linux-gnueabi-
}

AK3_DIR="$BASE_DIR/AnyKernel3"
[[ ! -d $AK3_DIR ]] && {
    msg ""
    msg "* Cloning AK3 Source..."
    git clone --depth=1 https://github.com/$KBUILD_BUILD_USER/AnyKernel3 "$BASE_DIR/AnyKernel3"
}

KERNEL_IMG="$KERNEL_DIR/out/arch/arm64/boot/Image.gz"
KERNEL_DTBO="$KERNEL_DIR/out/arch/arm64/boot/dtbo.img"
KERNEL_DTB="$KERNEL_DIR/out/arch/arm64/boot/dts/qcom/sm8150-v2.dtb"

CODENAME="vayu"
DEFCONFIG="vayu_defconfig"
CORES=$(grep -c ^processor /proc/cpuinfo)
CPU=$(lscpu | sed -nr '/Model name/ s/.*:\s*(.*) */\1/p')
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
COMMIT="$(git log --pretty=format:'%s' -1)"

CLANG_DIR="$BASE_DIR/"$1"-clang"
GCC64_DIR="$BASE_DIR/arm64"
GCC32_DIR="$BASE_DIR/arm32"
PrefixDir="$CLANG_DIR/bin/"

export TZ="Asia/Jakarta"
export CURRENTDATE=$(TZ=Asia/Jakarta date +"%A, %d %b %Y, %H:%M:%S")
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_COMPILER_STRING="$(${CLANG_DIR}/bin/clang --version | head -n 1 | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"
export PATH="$CLANG_DIR/bin:$GCC64_DIR/bin:$GCC32_DIR/bin:$PATH"

send_msg(){
    curl -s -X POST \
        https://api.telegram.org/bot"$TOKEN"/sendMessage \
        -d chat_id="$CHATID" \
        -d text="$1" \
        -d "parse_mode=html" \
        -d "disable_web_page_preview=true"
}

send_file(){
    curl -s -X POST \
        https://api.telegram.org/bot"$TOKEN"/sendDocument \
        -F chat_id="$CHATID" \
        -F document=@"$1" \
        -F caption="$2" \
        -F "parse_mode=html" \
        -F "disable_web_page_preview=true"
}

send_build_msg(){
send_msg "
<b>Build Triggered !</b>
<b>==================================</b>
<b>Device : </b>
<code>* $CODENAME</code>
<b>Branch : </b>
<code>* $BRANCH</code>
<b>Build Using : </b>
<code>* $CPU $CORES thread</code>
<b>Compiler : </b>
<code>* $KBUILD_COMPILER_STRING</code>
<b>Last Commit : </b>
<code>* $COMMIT</code>
<b>==================================</b>"
}

send_success_msg(){
send_msg "
<b>Build Success !</b>
<b>==================================</b>
<b>Build Date : </b>
<code>* $(date +"%A, %d %b %Y, %H:%M:%S")</code>
<b>Build Took : </b>
<code>* $(("$TOTAL_TIME" / 60)) Minutes, $(("$TOTAL_TIME" % 60)) Second.</code>
<b>==================================</b>"
}

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
    panel " ║ e. Back Main Menu                                               ║"
    panel " ╚═════════════════════════════════════════════════════════════════╝"
    panel2 " Enter your choice 1-9, or press 'e' for back to Main Menu : "

    read -r menu

    [[ "$menu" == "1" ]] && {
        make O=out $DEFCONFIG
        msg ""
        msg "(OK) Success export $DEFCONFIG to Out Dir"
        msg ""
    }

    [[ "$menu" == "2" ]] && {
        msg ""
        START=$(date +"%s")
        msg "(OK) Start Compile kernel for $CODENAME, started at $CURRENTDATE using $CPU $CORES thread"
        msg ""
        send_build_msg
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
            CROSS_COMPILE_ARM32=${ARM32} \
            Image.gz dtbo.img 2>&1 | tee out/log.txt
        [[ ! -e "$KERNEL_IMG" ]] && {
            err ""
            err "(X) Compile Kernel for $CODENAME failed, See buildlog to fix errors"
            err ""
            send_file "out/log.txt"
            send_msg "<b>Build Failed, See log to fix errors</b>"
            exit
        }
        END=$(date +"%s")
        TOTAL_TIME=$(("$END" - "$START"))
        msg ""
        msg "(OK) Compile Kernel for $CODENAME successfully, Kernel Image in $KERNEL_IMG"
        msg "(OK) Total time elapsed: $(("$TOTAL_TIME" / 60)) Minutes, $(("$TOTAL_TIME" % 60)) Second."
        msg ""
        send_success_msg
    }

    [[ "$menu" == "3" ]] && {
        msg ""
        START=$(date +"%s")
        msg "(OK) Start Compile kernel for $CODENAME, started at $CURRENTDATE using $CPU $CORES thread"
        msg ""
        send_build_msg
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
            LLVM=1 \
            Image.gz dtbo.img 2>&1 | tee out/log.txt
        [[ ! -e "$KERNEL_IMG" ]] && {
            err ""
            err "(X) Compile Kernel for $CODENAME failed, See buildlog to fix errors"
            err ""
            send_file "out/log.txt"
            send_msg "<b>Build Failed, See log to fix errors</b>"
            exit
        }
        END=$(date +"%s")
        TOTAL_TIME=$(("$END" - "$START"))
        msg ""
        msg "(OK) Compile Kernel for $CODENAME successfully, Kernel Image in $KERNEL_IMG"
        msg "(OK) Total time elapsed: $(("$TOTAL_TIME" / 60)) Minutes, $(("$TOTAL_TIME" % 60)) Second."
        msg ""
        send_success_msg
    }

    [[ "$menu" == "4" ]] && {
        cp "$KERNEL_IMG" "$AK3_DIR"
        msg ""
        msg "(OK) Done moving kernel img to $AK3_DIR"
        msg ""
    }

    [[ "$menu" == "5" ]] && {
        cp "$KERNEL_DTBO" "$AK3_DIR"
        msg ""
        msg "(OK) Done moving dtbo to $AK3_DIR"
        msg ""
    }

    [[ "$menu" == "6" ]] && {
        cp "$KERNEL_DTB" "$AK3_DIR/dtb"
        msg ""
        msg "(OK) Done moving dtb to $AK3_DIR"
        msg ""
    }

    [[ "$menu" == "7" ]] && {
        cd "$AK3_DIR"
        ZIP_NAME=["$(TZ=Asia/Jakarta date +'%Y%m%d')"]R.Y.N-"$(TZ=Asia/Jakarta date +"%H%M")".zip
        zip -r9 "$BASE_DIR/$ZIP_NAME" * -x .git README.md *placeholder
        cd "$KERNEL_DIR"
        msg ""
        msg "(OK) Done Zipping Kernel"
        msg ""
    }

    [[ "$menu" == "8" ]] && {
        send_file "out/log.txt"
        send_file "$BASE_DIR/$ZIP_NAME"
        send_msg "<b>md5 : </b><code>$(md5sum "$BASE_DIR/$ZIP_NAME" | cut -d' ' -f1)</code>"
        msg ""
        msg "(OK) Done Upload to Telegram"
        msg ""
    }

    [[ "$menu" == "e" ]] && exit

done
