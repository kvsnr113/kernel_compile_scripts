#!/usr/bin/env bash

export ARCH="arm64"
export SUBARCH="arm64"

# Set kernel source directory and base directory to place tools
KERNEL_DIR="$PWD"
cd ..
BASE_DIR="$PWD"
cd "$KERNEL_DIR"

# set your Telegram chat id & bot token 
TOKEN=
CHATID=

# Set device name
CODENAME=POCOF4
# Set defconfig to use
DEFCONFIG=vendor/munch_defconfig

# Set kernel image to use
K_IMG="$KERNEL_DIR/out/arch/arm64/boot/Image.gz"
K_DTBO="$KERNEL_DIR/out/arch/arm64/boot/dtbo.img"
K_DTB="$KERNEL_DIR/out/arch/arm64/boot/dtb.img"

# Set anything you want
export KBUILD_BUILD_USER=113
export KBUILD_BUILD_HOST=MiKaeNov
export TZ=Asia/Jakarta

CLANG_DIR="$BASE_DIR/clang"
        export ARM64="aarch64-linux-gnu-"
        export ARM32="arm-linux-gnueabi-"
        export PATH="/home/sie113/clang/bin:$PATH"

AK3_DIR="$BASE_DIR/AnyKernel3"
[[ ! -d "$AK3_DIR" ]] && {
        # Set AnyKernel3 repo to use
        AK3_LINK="https://github.com/kvsnr113/AnyKernel3"
        git clone --depth=1 "$AK3_LINK" "$BASE_DIR/AnyKernel3"
}

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
<b>Machine :</b>
<b>•</b> <code>$(lscpu | sed -nr '/Model name/ s/.*:\s*(.*) */\1/p')</code>
<b>•</b> RAM <code>$(cat /proc/meminfo | numfmt --field 2 --from-unit=Ki --to-unit=Mi | sed 's/ kB/M/g' | grep 'MemTotal' | awk -F ':' '{print $2}' | tr -d ' ')</code> | Free <code>$(cat /proc/meminfo | numfmt --field 2 --from-unit=Ki --to-unit=Mi | sed 's/ kB/M/g' | grep 'MemFree' | awk -F ':' '{print $2}' | tr -d ' ')</code> | Swap <code>$(cat /proc/meminfo | numfmt --field 2 --from-unit=Ki --to-unit=Mi | sed 's/ kB/M/g' | grep 'SwapTotal' | awk -F ':' '{print $2}' | tr -d ' ')</code>
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

miui_dtbo(){
        [[ "$1" == "apply" ]] && {
                sed -i 's/qcom,mdss-pan-physical-width-dimension = <70>;$/qcom,mdss-pan-physical-width-dimension = <695>;/' arch/arm64/boot/dts/vendor/qcom/dsi-panel-l11r-38-08-0a-dsc-cmd.dtsi
                sed -i 's/qcom,mdss-pan-physical-height-dimension = <155>;$/qcom,mdss-pan-physical-height-dimension = <1546>;/' arch/arm64/boot/dts/vendor/qcom/dsi-panel-l11r-38-08-0a-dsc-cmd.dtsi
        } 
         [[ "$1" == "revert" ]] && {
                 sed -i 's/qcom,mdss-pan-physical-width-dimension = <695>;$/qcom,mdss-pan-physical-width-dimension = <70>;/' arch/arm64/boot/dts/vendor/qcom/dsi-panel-l11r-38-08-0a-dsc-cmd.dtsi
                 sed -i 's/qcom,mdss-pan-physical-height-dimension = <1546>;$/qcom,mdss-pan-physical-height-dimension = <155>;/' arch/arm64/boot/dts/vendor/qcom/dsi-panel-l11r-38-08-0a-dsc-cmd.dtsi
        }
}

while true; do
        echo -e ""
        echo -e " Menu                                                               "
        echo -e " ╔════════════════════════════════════╗"
        echo -e " ║ 1. Export Defconfig                ║"
        echo -e " ║ 2. Start Build                     ║"
        echo -e " ║ f. Clean Out Directory             ║"
        echo -e " ║ e. Back Main Menu                  ║"
        echo -e " ╚════════════════════════════════════╝"
        echo -ne " Enter your choice, or press 'e' to exit : "
        read -r menu
        case "$menu" in 
        1 )
                make O=out "$DEFCONFIG"
                echo -e "(OK) Exported $DEFCONFIG to Out Dir !"
        ;;

        2 )
                START="$(date +"%s")"
                echo -e "(OK) [AOSP] Start Compiling Kernel !"
                send_build_msg
                        make -j"$(nproc --all)" O=out \
                                CC=clang \
                                CROSS_COMPILE=aarch64-linux-gnu- \
                                CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
                                LD=ld.lld \
                                LLVM=1 2>&1 | tee out/aosplog.txt

                [[ ! -e "$K_IMG" ]] && {
                        echo -e "(X) [AOSP] Kernel Build Error !"
                        send_file "out/aosplog.txt"
                        send_msg "<b>[AOSP] Kernel Build Error !</b>"
                        exit
                }

                cp "$K_IMG" "$AK3_DIR"
                [[ ! -z "$K_DTBO" ]] && cp "$K_DTBO" "$AK3_DIR"
                [[ ! -z "$K_DTB" ]] && cp "$K_DTB" "$AK3_DIR" && mv "$AK3_DIR/dtb.img" "$AK3_DIR/dtb"
                cd "$AK3_DIR"
                AOSP_ZIP_NAME=[KERNEL][AOSP]POCOF4-"$(date "+%Y%m%d-%H%M%S")".zip
                zip -r9 "$BASE_DIR/$AOSP_ZIP_NAME" * -x .git README.md *placeholder
                cd "$KERNEL_DIR"
                
                ###############
                # START MIUI BUILD
                ###############

                echo -e "(OK) [MIUI] Start Compiling Kernel !"

                rm -rf "$AK3_DIR/*.gz"
                rm -rf "$AK3_DIR/*.img"
                rm -rf "$AK3_DIR/*dtb"
                rm -rf "$K_IMG"
                rm -rf "$K_DTBO"
                rm -rf "$K_DTB"

                miui_dtbo "apply"

                make -j"$(nproc --all)" O=out \
                        CC=clang \
                        CROSS_COMPILE=aarch64-linux-gnu- \
                        CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
                        LD=ld.lld \
                        LLVM=1 2>&1 | tee out/miuilog.txt

                [[ ! -e "$K_IMG" ]] && {
                        echo -e "(X) [MIUI] Kernel Build Error !"
                        send_file "out/miuilog.txt"
                        send_msg "<b>[MIUI] Kernel Build Error !</b>"
                        exit
                }

                cp "$K_IMG" "$AK3_DIR"
                [[ ! -z "$K_DTBO" ]] && cp "$K_DTBO" "$AK3_DIR"
                [[ ! -z "$K_DTB" ]] && cp "$K_DTB" "$AK3_DIR" && mv "$AK3_DIR/dtb.img" "$AK3_DIR/dtb"
                cd "$AK3_DIR"
                MIUI_ZIP_NAME=[KERNEL][MIUI]POCOF4-"$(date "+%Y%m%d-%H%M%S")".zip
                zip -r9 "$BASE_DIR/$MIUI_ZIP_NAME" * -x .git README.md *placeholder
                cd "$KERNEL_DIR"

                miui_dtbo "revert"

                TOTAL_TIME=$(("$(date +"%s")" - "$START"))
                echo -e "(OK) [MIUI] Build success !"
                echo -e "(OK) Total Build Time Elapsed: $(("$TOTAL_TIME" / 60)) Minutes, $(("$TOTAL_TIME" % 60)) Second."
                send_success_msg

                ###########
                # UPLOAD FILES
                ###########
                
                send_file "out/aosplog.txt"
                send_file "out/miuilog.txt"
                send_msg "<b>CI Log Uploaded</b>"

                send_file "$BASE_DIR/$AOSP_ZIP_NAME" 
                send_msg "<b>[AOSP] Kernel Flashable Zip Uploaded (md5:</b><code>$(md5sum "$BASE_DIR/$AOSP_ZIP_NAME" | cut -d' ' -f1)</code>)"
                send_file "$BASE_DIR/$MIUI_ZIP_NAME" 
                send_msg "<b>[MIUI] Kernel Flashable Zip Uploaded (md5:</b><code>$(md5sum "$BASE_DIR/$MIUI_ZIP_NAME" | cut -d' ' -f1)</code>)"

                echo -e "(OK) Uploaded to Telegram !"
        ;;

        f )
                rm -rf out
        ;;

        e )
                exit
        ;;
        esac
done
