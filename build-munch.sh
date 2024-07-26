#!/usr/bin/env bash

# Set kernel source directory and base directory to place tools
KERNEL_DIR="$PWD"
cd ..
BASE_DIR="$PWD"
cd "$KERNEL_DIR"

export USE_CCACHE=1

[[ "$@" == *stable* ]] && TYPE=STABLE || TYPE=CI

setkernelname(){
        [[ "$1" == "stable" ]] && sed -i '/CONFIG_LOCALVERSION=/c\CONFIG_LOCALVERSION="-NOVA-[R6]"' out/.config || sed -i '/CONFIG_LOCALVERSION=/c\CONFIG_LOCALVERSION="-NOVA-[CI]"' out/.config
}

[[ "$@" == *flto* ]] && LTO=FULL || LTO=THIN
[[ "$@" == *dtbo* ]] && DTBO=1

[[ "$@" == *neutron* ]] && export PATH="$BASE_DIR/neutron-clang/bin:$PATH" && CLANG="Neutron Clang" || export PATH="$BASE_DIR/aosp-clang/bin:$PATH" && CLANG="AOSP Clang"

AK3_DIR="$BASE_DIR/AnyKernel3"
[[ ! -d "$AK3_DIR" ]] && echo -e "(X) Please Provide AnyKernel3 !" && exit

# Set your Telegram chat id & bot token / export it from .bashrc
TOKEN=
CHATID=

[[ "$@" == *munch* ]] && {
sed -i '/is_apollo/c\is_apollo=1;' $AK3_DIR/anykernel.sh
TARGET=munch
# Set device name
CODENAME=POCO-F4 
# Set defconfig to use
DEFCONFIG=vendor/munch_defconfig
# Set front zipname
KERNEL_NAME=MUNCH
}
[[ "$@" == *alioth* ]] && {
sed -i '/is_apollo/c\is_apollo=0;' $AK3_DIR/anykernel.sh
TARGET=alioth
# Set device name
CODENAME=POCO-F3
# Set defconfig to use
DEFCONFIG=vendor/alioth_defconfig
# Set front zipname
KERNEL_NAME=ALIOTH
}
[[ "$@" == *apollo* ]] && {
sed -i '/is_apollo/c\is_apollo=1;' $AK3_DIR/anykernel.sh
TARGET=apollo
# Set device name
CODENAME=Mi10T/Pro
# Set defconfig to use
DEFCONFIG=vendor/apollo_defconfig
# Set front zipname
KERNEL_NAME=APOLLO
}

# Set kernel image to use
K_IMG="$KERNEL_DIR/out/arch/arm64/boot/Image"
K_DTBO="$KERNEL_DIR/out/arch/arm64/boot/dtbo.img"
K_DTB="$KERNEL_DIR/out/arch/arm64/boot/dtb"

# Set anything you want
export ARCH="arm64"
export SUBARCH="arm64"
export KBUILD_BUILD_USER=Project113
export KBUILD_BUILD_HOST=Mikaela
export TZ=Asia/Jakarta

build_msg(){
send_msg "
<b>Build Triggered !</b>
<b>Machine :</b>
<b>•</b> <code>$(lscpu | sed -nr '/Model name/ s/.*:\s*(.*) */\1/p')</code>
<b>•</b> RAM <code>$(cat /proc/meminfo | numfmt --field 2 --from-unit=Ki --to-unit=Mi | sed 's/ kB/M/g' | grep 'MemTotal' | awk -F ':' '{print $2}' | tr -d ' ')</code> | Free <code>$(cat /proc/meminfo | numfmt --field 2 --from-unit=Ki --to-unit=Mi | sed 's/ kB/M/g' | grep 'MemFree' | awk -F ':' '{print $2}' | tr -d ' ')</code> | Swap <code>$(cat /proc/meminfo | numfmt --field 2 --from-unit=Ki --to-unit=Mi | sed 's/ kB/M/g' | grep 'SwapTotal' | awk -F ':' '{print $2}' | tr -d ' ')</code>
<b>==================================</b>
<b>Device : </b><code>$CODENAME</code>
<b>Branch : </b><code>$(git rev-parse --abbrev-ref HEAD)</code>
<b>Commit : </b><code>$(git log --pretty=format:'%s' -1)</code>
<b>Clang  : </b><code>$CLANG</code>
<b>==================================</b>"
}

success_msg(){
send_msg "
<b>Build Success !</b>
<b>==================================</b>
<b>Build Date : </b>
<code>$(date +"%A, %d %b %Y, %H:%M:%S")</code>
<b>Build Took : </b>
<code>$(("$TOTAL_TIME" / 60)) Minutes, $(("$TOTAL_TIME" % 60)) Second</code>
<b>==================================</b>"
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

miui_dtbo(){
        [[ "$1" == "APPLY" ]] && {
                sed -i 's/qcom,mdss-pan-physical-width-dimension = <70>;$/qcom,mdss-pan-physical-width-dimension = <695>;/' arch/arm64/boot/dts/vendor/qcom/dsi-panel-l11r-38-08-0a-dsc-cmd.dtsi
                sed -i 's/qcom,mdss-pan-physical-height-dimension = <155>;$/qcom,mdss-pan-physical-height-dimension = <1546>;/' arch/arm64/boot/dts/vendor/qcom/dsi-panel-l11r-38-08-0a-dsc-cmd.dtsi

                sed -i 's/qcom,mdss-pan-physical-width-dimension = <70>;$/qcom,mdss-pan-physical-width-dimension = <695>;/' arch/arm64/boot/dts/vendor/qcom/dsi-panel-j3s-37-02-0a-dsc-video.dtsi
                sed -i 's/qcom,mdss-pan-physical-height-dimension = <155>;$/qcom,mdss-pan-physical-height-dimension = <1546>;/' arch/arm64/boot/dts/vendor/qcom/dsi-panel-j3s-37-02-0a-dsc-video.dtsi
                
                sed -i 's/qcom,mdss-pan-physical-width-dimension = <70>;$/qcom,mdss-pan-physical-width-dimension = <695>;/'  arch/arm64/boot/dts/vendor/qcom/dsi-panel-k11a-38-08-0a-dsc-cmd.dtsi
                sed -i 's/qcom,mdss-pan-physical-height-dimension = <155>;$/qcom,mdss-pan-physical-height-dimension = <1546>;/'  arch/arm64/boot/dts/vendor/qcom/dsi-panel-k11a-38-08-0a-dsc-cmd.dtsi

        } 
         [[ "$1" == "REVERT" ]] && {
                sed -i 's/qcom,mdss-pan-physical-width-dimension = <695>;$/qcom,mdss-pan-physical-width-dimension = <70>;/' arch/arm64/boot/dts/vendor/qcom/dsi-panel-l11r-38-08-0a-dsc-cmd.dtsi
                sed -i 's/qcom,mdss-pan-physical-height-dimension = <1546>;$/qcom,mdss-pan-physical-height-dimension = <155>;/' arch/arm64/boot/dts/vendor/qcom/dsi-panel-l11r-38-08-0a-dsc-cmd.dtsi

                sed -i 's/qcom,mdss-pan-physical-width-dimension = <695>;$/qcom,mdss-pan-physical-width-dimension = <70>;/' arch/arm64/boot/dts/vendor/qcom/dsi-panel-j3s-37-02-0a-dsc-video.dtsi
                sed -i 's/qcom,mdss-pan-physical-height-dimension = <1546>;$/qcom,mdss-pan-physical-height-dimension = <155>;/' arch/arm64/boot/dts/vendor/qcom/dsi-panel-j3s-37-02-0a-dsc-video.dtsi

                sed -i 's/qcom,mdss-pan-physical-width-dimension = <695>;$/qcom,mdss-pan-physical-width-dimension = <70>;/'  arch/arm64/boot/dts/vendor/qcom/dsi-panel-k11a-38-08-0a-dsc-cmd.dtsi
                sed -i 's/qcom,mdss-pan-physical-height-dimension = <1546>;$/qcom,mdss-pan-physical-height-dimension = <155>;/'  arch/arm64/boot/dts/vendor/qcom/dsi-panel-k11a-38-08-0a-dsc-cmd.dtsi

        }
}

clearbuild(){
        rm -rf "$K_IMG"
        rm -rf "$K_DTB"
        rm -rf "$K_DTBO"
        rm -rf "out/arch/arm64/boot/dts/vendor/qcom"

        rm -rf "$AK3_DIR/Image"
        rm -rf "$AK3_DIR/Image.gz"
        rm -rf "$AK3_DIR/dtb"
        rm -rf "$AK3_DIR/dtbo.img"
}

zipbuild(){
        cp "$K_IMG" "$AK3_DIR"
        cp "$K_DTB" "$AK3_DIR"

        cd "$AK3_DIR"

        [[ "$@" == *AOSP* ]] && cp -af "$TARGET"-aospdtbo.img dtbo.img
        [[ "$@" == *MIUI* ]] && cp -af "$TARGET"-miuidtbo.img dtbo.img

        echo -e "(OK) Zipping "$1" Kernel !"

        [[ "$@" == *AOSP_NOKSU* ]] && AOSP_NOKSU_ZIP_NAME="["$KERNEL_NAME"-AOSP-NOKSU]["$(date "+%Y%m%d-%H%M%S")"]".zip && zip -r9 "$BASE_DIR/$AOSP_NOKSU_ZIP_NAME" * -x .git README.md *aospdtbo.img *miuidtbo.img
        [[ "$@" == *AOSP_KSU* ]] && AOSP_KSU_ZIP_NAME="["$KERNEL_NAME"-AOSP-KSU]["$(date "+%Y%m%d-%H%M%S")"]".zip && zip -r9 "$BASE_DIR/$AOSP_KSU_ZIP_NAME" * -x .git README.md *aospdtbo.img *miuidtbo.img
        [[ "$@" == *MIUI_NOKSU* ]] && MIUI_NOKSU_ZIP_NAME="["$KERNEL_NAME"-MIUI-NOKSU]["$(date "+%Y%m%d-%H%M%S")"]".zip && zip -r9 "$BASE_DIR/$MIUI_NOKSU_ZIP_NAME" * -x .git README.md *aospdtbo.img *miuidtbo.img
        [[ "$@" == *MIUI_KSU* ]] && MIUI_KSU_ZIP_NAME="["$KERNEL_NAME"-MIUI-KSU]["$(date "+%Y%m%d-%H%M%S")"]".zip && zip -r9 "$BASE_DIR/$MIUI_KSU_ZIP_NAME" * -x .git README.md *aospdtbo.img *miuidtbo.img

        cd "$KERNEL_DIR"
}

uploadbuild(){
        send_file "$BASE_DIR/$AOSP_NOKSU_ZIP_NAME" 
        send_file "$BASE_DIR/$AOSP_KSU_ZIP_NAME" 
        send_file "$BASE_DIR/$MIUI_NOKSU_ZIP_NAME" 
        send_file "$BASE_DIR/$MIUI_KSU_ZIP_NAME" 
        send_msg "<b>Kernel Flashable Zip Uploaded</b>"
}

compilebuild(){
        make -j"$(nproc --all)" O=out \
                CC=clang \
                CROSS_COMPILE=aarch64-linux-gnu- \
                CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
                CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
                LD=ld.lld AR=llvm-ar NM=llvm-nm \
                OBJCOPY=llvm-objcopy \
                OBJDUMP=llvm-objdump \
                STRIP=llvm-strip \
                LLVM=1 LLVM_IAS=1 \
                2>&1 | tee -a out/log.txt

         [[ ! -e "$K_IMG" ]] && { 
                echo -e "(X) Kernel Build Error !"
                send_file "out/log.txt"
                send_msg "<b>! Kernel Build Error !</b>"
                exit
        }
}

makebuild(){
        [[ "$@" == *COMPILE* ]] && {

                [[ "$TYPE" == "STABLE" ]] && setkernelname "stable" || setkernelname

                [[ "$1" == *KSU* ]] && sed -i '/CONFIG_KSU/c\CONFIG_KSU=y' out/.config
                [[ "$1" == *NOKSU* ]] && sed -i '/CONFIG_KSU/c\CONFIG_KSU=n' out/.config

                compilebuild

                [[ "$DTBO" == 1 ]] && {
                        [[ "$1" == *MIUI* ]] && rm -rf "$AK3_DIR/"$TARGET"-miuidtbo.img" && cp "$K_DTBO" "$AK3_DIR/"$TARGET"-miuidtbo.img"
                        [[ "$1" == *AOSP* ]] && rm -rf "$AK3_DIR/"$TARGET"-aospdtbo.img" && cp "$K_DTBO" "$AK3_DIR/"$TARGET"-aospdtbo.img"
                }
        }

        zipbuild "$1" "$2"
}

while true; do
        echo -e ""
        echo -e " Menu                                                               "
        echo -e " ╔════════════════════════════════════╗"
        echo -e " ║ 1. Export Defconfig                ║"
        echo -e " ║ 2. Start Build                     ║"
        echo -e " ║ 3. Upload Kranul                   ║"
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
                [[ $LTO == "FULL" ]] && sed -i '/CONFIG_LTO_CLANG_THIN/c\CONFIG_LTO_CLANG_THIN=n' out/.config && sed -i '/CONFIG_LTO_CLANG_FULL/c\CONFIG_LTO_CLANG_FULL=y' out/.config
                [[ $LTO == "THIN" ]] && sed -i '/CONFIG_LTO_CLANG_THIN/c\CONFIG_LTO_CLANG_THIN=y' out/.config && sed -i '/CONFIG_LTO_CLANG_FULL/c\CONFIG_LTO_CLANG_FULL=n' out/.config

                START="$(date +"%s")"

                build_msg

                [[ "$DTBO" == 1 ]] && {
                        send_msg "<b>AOSP DTBO Updated</b>"
                        send_msg "<b>MIUI DTBO Updated</b>"
                }

                clearbuild
                makebuild "AOSP_KSU" "RECOMPILE"
                miui_dtbo "APPLY"
                [[ "$DTBO" == 1 ]] && makebuild "MIUI_KSU" "RECOMPILE" || makebuild "MIUI_KSU"
                miui_dtbo "REVERT"
                clearbuild
                makebuild "AOSP_NOKSU" "RECOMPILE"
                miui_dtbo "APPLY"
                [[ "$DTBO" == 1 ]] && makebuild "MIUI_NOKSU" "RECOMPILE" || makebuild "MIUI_NOKSU"
                miui_dtbo "REVERT"
                clearbuild

                TOTAL_TIME=$(("$(date +"%s")" - "$START"))

                success_msg

                send_file "out/log.txt"
                send_msg "<b>CI Log Uploaded</b>"
                rm -rf out/log.txt

                [[ "$@" == *upload* ]] && uploadbuild

                git restore arch/arm64/boot/dts/vendor/qcom "arch/arm64/configs/$DEFCONFIG"
        ;;

        3 )
                uploadbuild
        ;;

        f )
                rm -rf out
        ;;

        e )
                exit
        ;;
        esac
done
