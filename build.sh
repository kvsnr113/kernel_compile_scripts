#!/usr/bin/env bash
# Copyright ©2022 XSans02 - Modified by 113
# Kernel Build Script

export TZ="Asia/Jakarta"

[[ -z "$1" ]] && {
        echo -e "Please Specify Your Compiler (weebx/azure/proton/sd/aosp) !"
        exit
}

KERNEL_DIR="$PWD"
cd ..
BASE_DIR="$PWD"
cd "$KERNEL_DIR"

CPU="$(lscpu | sed -nr '/Model name/ s/.*:\s*(.*) */\1/p')"

TOKEN="5382711200:AAFp0g3MrphAUgylIq8ynMAbfeOys8lzWTI"
CHATID="-1001586260532"

CODENAME="vayu"
DEFCONFIG="vayu_defconfig"

export KBUILD_BUILD_USER="kvsnr113"
export KBUILD_BUILD_HOST="projkt113"

[[ -z "$TOKEN" ]] || [[ -z "$CHATID" ]] && {
        echo -e "(X) Something Missing ! , Check Token / Chat ID Variable !"
        echo -e "Enter Your Telegram Chat ID :"
        read -r chatid
        CHATID="$chatid"
        echo -e "Enter Your Telegram Bot Token :"
        read -r token
        TOKEN="$token"
}

CLANG_DIR="$BASE_DIR/"$1"-clang"
if [[ "$1" == "weebx" ]]; then
        [[ ! -d "$BASE_DIR/"$1"-clang" ]] && {
                wget https://github.com/XSans02/WeebX-Clang/raw/main/WeebX-Clang-link.txt -O link.txt && wget $(cat link.txt) -O "WeebX-Clang.tar.gz"
                mkdir $BASE_DIR/"$1"-clang && tar -xf WeebX-Clang.tar.gz -C $BASE_DIR/"$1"-clang && rm -rf WeebX-Clang.tar.gz link.txt
        }
elif [[ "$1" == "azure" ]]; then
        [[ ! -d "$BASE_DIR/"$1"-clang" ]] && git clone --depth=1 https://gitlab.com/Panchajanya1999/azure-clang $BASE_DIR/"$1"-clang
elif [[ "$1" == "sd" ]]; then
        [[ ! -d "$BASE_DIR/"$1"-clang" ]] && git clone --depth=1 https://github.com/ZyCromerZ/SDClang $BASE_DIR/"$1"-clang
elif [[ "$1" == "aosp" ]]; then
        [[ ! -d "$BASE_DIR/"$1"-clang" ]] && {
                CVER="r450784e"
                wget https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/master/clang-"$CVER".tar.gz
                mkdir $BASE_DIR/"$1"-clang && tar -xf clang-"$CVER".tar.gz -C $BASE_DIR/"$1"-clang && rm -rf clang-"$CVER".tar.gz
        }
fi

[[ "$1" == "sd" ]] || [[ "$1" == "aosp" ]] && {
        [[ ! -d "$BASE_DIR/arm32" ]] && git clone --depth=1 https://github.com/XSans02/arm-linux-androideabi-4.9 "$BASE_DIR"/arm32
        [[ ! -d "$BASE_DIR/arm64" ]] && git clone --depth=1 https://github.com/XSans02/aarch64-linux-android-4.9 "$BASE_DIR"/arm64
        ARM64="aarch64-linux-android-"
        ARM32="arm-linux-androideabi-"
        GCC64_DIR="$BASE_DIR/arm64"
        GCC32_DIR="$BASE_DIR/arm32"
        PREFIXDIR="$CLANG_DIR/bin/"
        export PATH="$CLANG_DIR/bin:$GCC64_DIR/bin:$GCC32_DIR/bin:$PATH"
} || {
        ARM64="aarch64-linux-gnu-"
        ARM32="arm-linux-gnueabi-"
        export PATH="$CLANG_DIR/bin:$PATH"
}

COMPILER="$(${CLANG_DIR}/bin/clang --version | head -n 1 | sed 's/[[:space:]]*$//;s/ ([^()]*)//g')"

AK3_DIR="$BASE_DIR/AnyKernel3"
[[ ! -d "$AK3_DIR" ]] && git clone --depth=1 https://github.com/$KBUILD_BUILD_USER/AnyKernel3 "$BASE_DIR/AnyKernel3"

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
<b>Build With</b>
<b>•</b> <code>$CPU</code>
<b>•</b> RAM <code>$(cat /proc/meminfo | numfmt --field 2 --from-unit=Ki --to-unit=Mi | sed 's/ kB/M/g' | grep 'MemTotal' | awk -F ':' '{print $2}' | tr -d ' ')</code> | Free <code>$(cat /proc/meminfo | numfmt --field 2 --from-unit=Ki --to-unit=Mi | sed 's/ kB/M/g' | grep 'MemFree' | awk -F ':' '{print $2}' | tr -d ' ')</code> | Swap <code>$(cat /proc/meminfo | numfmt --field 2 --from-unit=Ki --to-unit=Mi | sed 's/ kB/M/g' | grep 'SwapTotal' | awk -F ':' '{print $2}' | tr -d ' ')</code>
<b>•</b> <code>$COMPILER</code>
<b>==================================</b>
<b>Device : </b><code>$CODENAME</code>
<b>Branch : </b><code>$(git rev-parse --abbrev-ref HEAD)</code>
<b>Commit : </b><code>$(git log --pretty=format:'%s' -1)</code>
<b>==================================</b>"
}

send_success_msg(){
send_msg "
<b>Build Success !</b>
<b>==================================</b>
<b>Build Date : </b>
<code>$(date +"%A, %d %b %Y, %H:%M:%S")</code>
<b>Build Took : </b>
<code>$(("$TOTAL_TIME" / 60)) Minutes, $(("$TOTAL_TIME" % 60)) Second</code>
<b>==================================</b>"
}

export ARCH="arm64"
export SUBARCH="arm64"

while true; do
        echo -e ""
        echo -e " Menu                                                               "
        echo -e " ╔═════════════════════════════════════════════════════════════════╗"
        echo -e " ║ 1. Export defconfig to Out Dir                                  ║"
        echo -e " ║ 2. Start Compile                                                ║"
        echo -e " ║ 3. Make Zip                                                     ║"
        echo -e " ║ 4. Upload to Telegram                                           ║"
        echo -e " ║ e. Back Main Menu                                               ║"
        echo -e " ╚═════════════════════════════════════════════════════════════════╝"
        echo -ne " Enter your choice, or press 'e' to exit : "
        read -r menu

        [[ "$menu" == "1" ]] && {
                make O=out "$DEFCONFIG"
                echo -e "(OK) Exported $DEFCONFIG to Out Dir !"
        }
        [[ "$menu" == "2" ]] && {
                START="$(date +"%s")"
                echo -e "(OK) Start Compiling kernel !"
                send_build_msg
                [[ "$1" == "sd" ]] || [[ "$1" == "aosp" ]] && {
                        make -j"$(nproc --all)" O=out \
                                CC=clang \
                                LD=${PREFIXDIR}ld.lld \
                                AR=${PREFIXDIR}llvm-ar \
                                NM=${PREFIXDIR}llvm-nm \
                                AS=${PREFIXDIR}llvm-as \
                                STRIP=${PREFIXDIR}llvm-strip \
                                OBJCOPY=${PREFIXDIR}llvm-objcopy \
                                OBJDUMP=${PREFIXDIR}llvm-objdump \
                                OBJSIZE=${PREFIXDIR}llvm-size \
                                READELF=${PREFIXDIR}llvm-readelf \
                                HOSTCC=clang \
                                HOSTCXX=clang++ \
                                HOSTAR=${PREFIXDIR}llvm-ar \
                                HOSTLD=${PREFIXDIR}ld.lld \
                                CLANG_TRIPLE=aarch64-linux-gnu- \
                                CROSS_COMPILE=${ARM64} \
                                CROSS_COMPILE_ARM32=${ARM32} \
                                LLVM=1 \
                                Image.gz 2>&1 | tee out/log.txt
                } || {
                        make -j"$(nproc --all)" O=out \
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
                                Image.gz 2>&1 | tee out/log.txt
                }
                [[ ! -e "$KERNEL_DIR/out/arch/arm64/boot/Image.gz" ]] && {
                        echo -e "(X) Build error !"
                        send_file "out/log.txt"
                        send_msg "<b>Build error !</b>"
                        exit
                }
                TOTAL_TIME=$(("$(date +"%s")" - "$START"))
                echo -e "(OK) Build success !"
                echo -e "(OK) Total time elapsed: $(("$TOTAL_TIME" / 60)) Minutes, $(("$TOTAL_TIME" % 60)) Second."
                send_success_msg
                send_file "out/log.txt"
        }
        [[ "$menu" == "3" ]] && {
                cp "$KERNEL_DIR/out/arch/arm64/boot/Image.gz" "$AK3_DIR"
                cp "$KERNEL_DIR/out/arch/arm64/boot/dts/qcom/vayu-sm8150-overlay.dtbo" "$AK3_DIR/dtbo.img"
                cp "$KERNEL_DIR/out/arch/arm64/boot/dts/qcom/sm8150-v2.dtb" "$AK3_DIR/dtb"
                cd "$AK3_DIR"
                ZIP_NAME=["$(date +"%Y%m%d")"]R.Y.N-"$(date +"%H%M")".zip
                zip -r9 "$BASE_DIR/$ZIP_NAME" * -x .git README.md *placeholder
                cd "$KERNEL_DIR"
                echo -e "(OK) Kernel Zipped !"
        }
        [[ "$menu" == "4" ]] && {
                send_file "$BASE_DIR/$ZIP_NAME"
                send_msg "<b>md5 : </b><code>$(md5sum "$BASE_DIR/$ZIP_NAME" | cut -d' ' -f1)</code>"
                echo -e "(OK) Uploaded to Telegram !"
        }
        [[ "$menu" == "e" ]] && exit
done
