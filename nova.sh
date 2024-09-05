#!/usr/bin/env bash

# Set kernel source directory and base directory to place tools
KERNEL_DIR="$PWD"
cd ..
BASE_DIR="$PWD"
cd $KERNEL_DIR
AK3_DIR=$BASE_DIR/AnyKernel3
[[ ! -d "$AK3_DIR" ]] && echo -e "(X) Please Provide AnyKernel3 !" && exit

[[ "$@" == *stable* ]] && TYPE=STABLE || TYPE=CI
[[ "$@" == *aospclang* ]] && export PATH="$BASE_DIR/aosp-clang/bin:$PATH" && CLANG="AOSP Clang" ||  export PATH="$BASE_DIR/neutron-clang/bin:$PATH" && CLANG="Neutron Clang"

[[ "$@" == *munch* ]] && {
        sed -i '/is_apollo=/c\is_apollo=0;' $AK3_DIR/anykernel.sh
        sed -i '/is_munch=/c\is_munch=1;' $AK3_DIR/anykernel.sh
        sed -i '/is_alioth=/c\is_alioth=0;' $AK3_DIR/anykernel.sh
        sed -i '/device.name1=/c\device.name1=munch' $AK3_DIR/anykernel.sh
        sed -i '/device.name2=/c\device.name2=munchin' $AK3_DIR/anykernel.sh
        TARGET=munch
        # Set device name
        CODENAME=POCO-F4 
        # Set defconfig to use
        DEFCONFIG=vendor/munch_defconfig
        # Set front zipname
        KERNEL_NAME=MUNCH
}

[[ "$@" == *alioth* ]] && {
        sed -i '/is_apollo=/c\is_apollo=0;' $AK3_DIR/anykernel.sh
        sed -i '/is_munch=/c\is_munch=0;' $AK3_DIR/anykernel.sh
        sed -i '/is_alioth=/c\is_alioth=1;' $AK3_DIR/anykernel.sh
        sed -i '/device.name1=/c\device.name1=alioth' $AK3_DIR/anykernel.sh
        sed -i '/device.name2=/c\device.name2=aliothin' $AK3_DIR/anykernel.sh
        TARGET=alioth
        # Set device name
        CODENAME=POCO-F3
        # Set defconfig to use
        DEFCONFIG=vendor/alioth_defconfig
        # Set front zipname
        KERNEL_NAME=ALIOTH
}

[[ "$@" == *apollo* ]] && {
        sed -i '/is_apollo=/c\is_apollo=1;' $AK3_DIR/anykernel.sh
        sed -i '/is_munch=/c\is_munch=0;' $AK3_DIR/anykernel.sh
        sed -i '/is_alioth=/c\is_alioth=0;' $AK3_DIR/anykernel.sh
        sed -i '/device.name1=/c\device.name1=apollo' $AK3_DIR/anykernel.sh
        sed -i '/device.name2=/c\device.name2=apollon' $AK3_DIR/anykernel.sh
        TARGET=apollo
        # Set device name
        CODENAME=Mi10T/Pro
        # Set defconfig to use
        DEFCONFIG=vendor/apollo_defconfig
        # Set front zipname
        KERNEL_NAME=APOLLO
}

# Set kernel image to use
K_IMG=$KERNEL_DIR/out/arch/arm64/boot/Image
K_DTBO=$KERNEL_DIR/out/arch/arm64/boot/dtbo.img
K_DTB=$KERNEL_DIR/out/arch/arm64/boot/dtb

# Set your Telegram chat id & bot token / export it from .bashrc
TOKEN=
CHATID=

# Set anything you want
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER=Project113
export KBUILD_BUILD_HOST=Minsae
export TZ=Asia/Jakarta

setkernelname(){
        [[ "$1" == "stable" ]] && sed -i '/CONFIG_LOCALVERSION=/c\CONFIG_LOCALVERSION="-E404-[ST]"' out/.config || sed -i '/CONFIG_LOCALVERSION=/c\CONFIG_LOCALVERSION="-E404-[CI]"' out/.config
}

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
<code>$(($TOTAL_TIME / 60)) Minutes, $(($TOTAL_TIME % 60)) Second</code>
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

kernelsu(){
        [[ "$1" == "1" ]] && sed -i '/CONFIG_KSU/c\CONFIG_KSU=y' out/.config
        [[ "$1" == "0" ]] && sed -i '/CONFIG_KSU/c\CONFIG_KSU=n' out/.config
}
miui_dtbo(){
        [[ "$1" == "APPLY" ]] && {
                sed -i 's/qcom,mdss-pan-physical-width-dimension = <70>;$/qcom,mdss-pan-physical-width-dimension = <695>;/' arch/arm64/boot/dts/vendor/qcom/dsi-panel-l11r-38-08-0a-dsc-cmd.dtsi
                sed -i 's/qcom,mdss-pan-physical-height-dimension = <155>;$/qcom,mdss-pan-physical-height-dimension = <1546>;/' arch/arm64/boot/dts/vendor/qcom/dsi-panel-l11r-38-08-0a-dsc-cmd.dtsi

                sed -i 's/qcom,mdss-pan-physical-width-dimension = <70>;$/qcom,mdss-pan-physical-width-dimension = <700>;/' arch/arm64/boot/dts/vendor/qcom/dsi-panel-j3s-37-02-0a-dsc-video.dtsi
                sed -i 's/qcom,mdss-pan-physical-height-dimension = <154>;$/qcom,mdss-pan-physical-height-dimension = <1540>;/' arch/arm64/boot/dts/vendor/qcom/dsi-panel-j3s-37-02-0a-dsc-video.dtsi
                
                sed -i 's/qcom,mdss-pan-physical-width-dimension = <70>;$/qcom,mdss-pan-physical-width-dimension = <700>;/'  arch/arm64/boot/dts/vendor/qcom/dsi-panel-k11a-38-08-0a-dsc-cmd.dtsi
                sed -i 's/qcom,mdss-pan-physical-height-dimension = <155>;$/qcom,mdss-pan-physical-height-dimension = <1540>;/'  arch/arm64/boot/dts/vendor/qcom/dsi-panel-k11a-38-08-0a-dsc-cmd.dtsi
        }

        [[ "$1" == "REVERT" ]] && git restore arch/arm64/boot/dts/vendor/qcom/dsi-panel-*
}

effcpu() {
        [[ "$1" == "APPLY" ]] && {
                # little
                sed -i '/<1708800>,/c\<1708800>;' arch/arm64/boot/dts/vendor/qcom/kona.dtsi
                sed -i '/<1804800>;/c\//<1804800>;' arch/arm64/boot/dts/vendor/qcom/kona.dtsi
                # big
                sed -i '/<2342400>,/c\<2342400>;' arch/arm64/boot/dts/vendor/qcom/kona.dtsi
                sed -i '/<2419200>;/c\//<2419200>;' arch/arm64/boot/dts/vendor/qcom/kona.dtsi
                # prime
                sed -i '/<2553600>,/c\<2553600>;' arch/arm64/boot/dts/vendor/qcom/kona.dtsi
                sed -i '/<2649600>,/c\//<2649600>,' arch/arm64/boot/dts/vendor/qcom/kona.dtsi
                sed -i '/<2745600>,/c\//<2745600>,' arch/arm64/boot/dts/vendor/qcom/kona.dtsi
                sed -i '/<2841600>,/c\//<2841600>,' arch/arm64/boot/dts/vendor/qcom/kona.dtsi
                sed -i '/<3187200>;/c\//<3187200>;' arch/arm64/boot/dts/vendor/qcom/kona.dtsi
        }

        [[ "$1" == "REVERT" ]] && git restore arch/arm64/boot/dts/vendor/qcom/kona.dtsi
}

clearbuild(){
        rm -rf $K_IMG
        rm -rf $K_DTB
        rm -rf $K_DTBO
        rm -rf out/arch/arm64/boot/dts/vendor/qcom
}

zipbuild(){
        echo -e "(OK) Zipping Kernel !"

        cd "$AK3_DIR"

        ZIP_NAME="[E404-"$KERNEL_NAME"]["$(date "+%Y%m%d-%H%M%S")"]".zip
        zip -r9 "$BASE_DIR/$ZIP_NAME" */ anykernel.sh $TARGET* -x .git README.md LICENSE

        cd $KERNEL_DIR
}

uploadbuild(){
        send_file "$BASE_DIR/$ZIP_NAME" 
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

         [[ ! -e $K_IMG ]] && { 
                echo -e "(X) Kernel Build Error !"
                send_file "out/log.txt"
                git restore arch/arm64/boot/dts/vendor/qcom arch/arm64/configs/$DEFCONFIG
                send_msg "<b>! Kernel Build Error !</b>"
                exit
        }
}

makebuild(){
        [[ "$TYPE" == "STABLE" ]] && setkernelname "stable" || setkernelname

        [[ "$@" == *MAIN* ]] && {
                kernelsu "0"
                compilebuild
        } || {
                [[ "$@" == *KSU* ]] && kernelsu "1"
                [[ "$@" == *EFFCPU* ]] && effcpu "APPLY"
                [[ "$@" == *MIUI* ]] && miui_dtbo "APPLY"
                compilebuild
                [[ "$@" == *EFFCPU* ]] && effcpu "REVERT"
                [[ "$@" == *MIUI* ]] && miui_dtbo "REVERT"
        }

        [[ "$@" == *MAIN* ]] && {
                cp $K_IMG $AK3_DIR/"$TARGET"-noksu-Image
                cp $K_DTBO $AK3_DIR/"$TARGET"-normal-dtbo.img
                cp $K_DTB $AK3_DIR/"$TARGET"-normal-dtb
        } || {
                [[ "$@" == *KSU* ]] && cp $K_IMG $AK3_DIR/"$TARGET"-ksu-Image
                [[ "$@" == *MIUI* ]] && cp $K_DTBO $AK3_DIR/"$TARGET"-miui-dtbo.img
                [[ "$@" == *EFFCPU* ]] && cp $K_DTB $AK3_DIR/"$TARGET"-effcpu-dtb
        }
}

while true; do
        echo -e ""
        echo -e " Menu "
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
                make O=out $DEFCONFIG
                echo -e "(OK) Exported $DEFCONFIG to Out Dir !"
        ;;

        2 )
                START="$(date +"%s")"

                build_msg

                clearbuild

                makebuild "MAIN"
                makebuild "MIUI" "KSU" "EFFCPU" # dirty build only to take miui dtbo, effcpu dtb, and noksu kernel image

                zipbuild

                clearbuild

                TOTAL_TIME=$(("$(date +"%s")" - "$START"))

                success_msg

                send_file "out/log.txt"
                send_msg "<b>CI Log Uploaded</b>"
                rm -rf out/log.txt

                [[ "$@" == *upload* ]] && uploadbuild

                git restore arch/arm64/boot/dts/vendor/qcom arch/arm64/configs/$DEFCONFIG
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
