#!/usr/bin/env bash

# Set kernel source directory and base directory to place tools
KERNEL_DIR="$PWD"
cd ..
BASE_DIR="$PWD"
cd $KERNEL_DIR

AK3_DIR=$BASE_DIR/AnyKernel3
[[ ! -d "$AK3_DIR" ]] && echo -e "(X) Please Provide AnyKernel3 !" && exit

case "$@" in
        *stable*) 
        TYPE=STABLE
        ;;
        *port*) then
        TYPE=PORT
        ;;
        *dev*) then
        TYPE=DEV
        ;;
        *)
        TYPE=CI
        ;;
esac
case "$@" in
        *aosp*)
        export PATH="$BASE_DIR/aosp-clang/bin:$PATH" && TC="AOSP-Clang"
        ;;
        *gcc*)
        GCC64_DIR="$BASE_DIR/*gcc*/gcc-arm64/bin/"
        GCC32_DIR="$BASE_DIR/*gcc*/gcc-arm/bin/"
        export PATH="$GCC64_DIR:$GCC32_DIR:/usr/bin:$PATH"
        export KBUILD_COMPILER_STRING="$("$GCC64_DIR"aarch64-elf-gcc --version | head -n 1)"
        TC="GCC"
        ;;
        *)
        export PATH="$BASE_DIR/neutron-clang/bin:$PATH" && TC="Neutron-Clang"
        #export PATH="$BASE_DIR/aosp-clang/bin:$PATH" && TC="AOSP-Clang"
        ;;
esac
case "$@" in
        *munch*)
        sed -i '/devicename=/c\devicename=munch;' $AK3_DIR/anykernel.sh
        TARGET=MUNCH 
        DEFCONFIG=vendor/munch_defconfig
        ;;
        *alioth*)
        sed -i '/devicename=/c\devicename=alioth;' $AK3_DIR/anykernel.sh
        TARGET=ALIOTH
        DEFCONFIG=vendor/alioth_defconfig
        ;;
        *apollo*)
        sed -i '/devicename=/c\devicename=apollo;' $AK3_DIR/anykernel.sh
        TARGET=APOLLO
        DEFCONFIG=vendor/apollo_defconfig
        ;;
        *lmi*)
        sed -i '/devicename=/c\devicename=lmi;' $AK3_DIR/anykernel.sh
        TARGET=LMI
        DEFCONFIG=vendor/lmi_defconfig
        ;;
        *umi*)
        sed -i '/devicename=/c\devicename=umi;' $AK3_DIR/anykernel.sh
        TARGET=UMI
        DEFCONFIG=vendor/umi_defconfig
        ;;
        *cmi*)
        sed -i '/devicename=/c\devicename=cmi;' $AK3_DIR/anykernel.sh
        TARGET=CMI
        DEFCONFIG=vendor/cmi_defconfig
        ;;
        *cas*)
        sed -i '/devicename=/c\devicename=cas;' $AK3_DIR/anykernel.sh
        TARGET=CAS
        DEFCONFIG=vendor/cas_defconfig
        ;;
esac

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
export KBUILD_BUILD_USER=vyn
export KBUILD_BUILD_HOST=fedora
export TZ=Asia/Jakarta

setkernelname(){
        if [[ "$TYPE" == "STABLE" ]]; then
                sed -i '/CONFIG_LOCALVERSION=/c\CONFIG_LOCALVERSION="-E404R"' out/.config
        elif [[ "$TYPE" == "DEV" ]]; then
                sed -i '/CONFIG_LOCALVERSION=/c\CONFIG_LOCALVERSION="-E404R"' out/.config
        else
                sed -i '/CONFIG_LOCALVERSION=/c\CONFIG_LOCALVERSION="-E404R"' out/.config
        fi
}

build_msg(){
send_msg "
<b>Build Triggered !</b>
<b>Machine :</b>
<b>•</b> <code>$(lscpu | sed -nr '/Model name/ s/.*:\s*(.*) */\1/p')</code>
<b>•</b> RAM <code>$(cat /proc/meminfo | numfmt --field 2 --from-unit=Ki --to-unit=Mi | sed 's/ kB/M/g' | grep 'MemTotal' | awk -F ':' '{print $2}' | tr -d ' ')</code> | Free <code>$(cat /proc/meminfo | numfmt --field 2 --from-unit=Ki --to-unit=Mi | sed 's/ kB/M/g' | grep 'MemFree' | awk -F ':' '{print $2}' | tr -d ' ')</code> | Swap <code>$(cat /proc/meminfo | numfmt --field 2 --from-unit=Ki --to-unit=Mi | sed 's/ kB/M/g' | grep 'SwapTotal' | awk -F ':' '{print $2}' | tr -d ' ')</code>
<b>==================================</b>
<b>Device : </b><code>$TARGET</code>
<b>Branch : </b><code>$(git rev-parse --abbrev-ref HEAD)</code>
<b>Commit : </b><code>$(git log --pretty=format:'%s' -1)</code>
<b>TC     : </b><code>$TC</code>
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

clearbuild(){
        rm -rf $K_IMG
        rm -rf $K_DTB
        rm -rf $K_DTBO
        rm -rf out/arch/arm64/boot/dts/vendor/qcom
}

zipbuild(){
        echo -e "(OK) Zipping Kernel !"

        cd "$AK3_DIR"

        ZIP_NAME="E404R-"$TARGET"-"$TYPE"-"$(date "+%Y%m%d")"".zip
        zip -r9 "$BASE_DIR/$ZIP_NAME" */ $TARGET* anykernel.sh -x .git README.md LICENSE

        cd $KERNEL_DIR
}

uploadbuild(){
        send_file "$BASE_DIR/$ZIP_NAME" 
        send_msg "<b>Kernel Flashable Zip Uploaded</b>"
}

compilebuild(){
        if [[ $TC == *Clang* ]]; then
        make -kj"$(nproc --all)" O=out \
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
        else
        echo "Compiling with GCC"
        make -kj$(nproc --all) O=out \
	        AR=llvm-ar \
	        NM=llvm-nm \
 	        CC=aarch64-elf-gcc \
  	        LD=aarch64-elf-ld.lld \
	        CC_COMPAT=arm-eabi-gcc \
	        OBJCOPY=llvm-objcopy \
	        OBJDUMP=llvm-objdump \
	        OBJCOPY=llvm-objcopy \
	        OBJSIZE=llvm-size \
	        STRIP=llvm-strip \
	        CROSS_COMPILE=aarch64-elf- \
	        CROSS_COMPILE_COMPAT=arm-eabi- \
                2>&1 | tee -a out/log.txt
        fi

         [[ ! -e $K_IMG ]] && { 
                echo -e "(X) Kernel Build Error !"
                send_file "out/log.txt"
                git restore arch/arm64/configs/$DEFCONFIG
                send_msg "<b>! Kernel Build Error !</b>"
                exit

                if [[ "$TC" == "GreenForce-Clang" ]]; then
                        git restore Makefile
                fi
        }
}

makebuild(){
        [[ "$TYPE" == "STABLE" ]] && setkernelname "stable" || setkernelname
        
        compilebuild

        cp $K_IMG $AK3_DIR/"$TARGET"-Image
        cp $K_DTBO $AK3_DIR/"$TARGET"-dtbo.img
        cp $K_DTB $AK3_DIR/"$TARGET"-dtb
}

while true; do
        echo -e ""
        echo -e " Menu "
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
                make O=out $DEFCONFIG
                echo -e "(OK) Exported $DEFCONFIG to Out Dir !"
        ;;

        2 )
                START="$(date +"%s")"

                sed -i '/CONFIG_KALLSYMS=/c\CONFIG_KALLSYMS=n' out/.config
                sed -i '/CONFIG_KALLSYMS_BASE_RELATIVE=/c\CONFIG_KALLSYMS_BASE_RELATIVE=n' out/.config

                if [[ "$TYPE" == "PORT" ]]; then
                        sed -i '/CONFIG_E404_OPLUS/c\CONFIG_E404_OPLUS=y' out/.config
                        sed -i '/devicecheck=/c\devicecheck=0;' $AK3_DIR/anykernel.sh
                else
                        sed -i '/devicecheck=/c\devicecheck=0;' $AK3_DIR/anykernel.sh
                fi

                if [[ "$TYPE" == "DEV" ]]; then
                        sed -i '/CONFIG_STACKTRACE=/c\CONFIG_STACKTRACE=n' out/.config
                        #sed -i '/CONFIG_RELOCATABLE=/c\CONFIG_RELOCATABLE=n' out/.config
                        #sed -i '/CONFIG_RANDOMIZE_BASE=/c\CONFIG_RANDOMIZE_BASE=n' out/.config
                        sed -i '/CONFIG_NTFS_FS=/c\CONFIG_NTFS_FS=n' out/.config
                fi
                        
                if [[ "$TC" != *GCC* ]]; then
                        if [[ "$TYPE" == "FLTO" ]]; then
                                sed -i '/CONFIG_LTO_CLANG_THIN/c\CONFIG_LTO_CLANG_THIN=n' out/.config
                                sed -i '/CONFIG_LTO_CLANG_FULL/c\CONFIG_LTO_CLANG_FULL=y' out/.config
                        else 
                                sed -i '/CONFIG_LTO_CLANG_THIN/c\CONFIG_LTO_CLANG_THIN=y' out/.config
                                sed -i '/CONFIG_LTO_CLANG_FULL/c\CONFIG_LTO_CLANG_FULL=n' out/.config
                        fi
                else
                        sed -i '/CONFIG_LTO_NONE/c\CONFIG_LTO_NONE=y' out/.config
                        sed -i '/CONFIG_LTO=/c\CONFIG_LTO=n' out/.config
                        #sed -i '/CONFIG_LTO_GCC/c\CONFIG_LTO_GCC=y' out/.config
                        sed -i '/CONFIG_LTO_CLANG=/c\# CONFIG_LTO_CLANG is not set' out/.config
                        sed -i '/CONFIG_LTO_CLANG_THIN/c\# CONFIG_LTO_CLANG_THIN is not set' out/.config
                        sed -i '/CONFIG_LTO_CLANG_FULL/c\# CONFIG_LTO_CLANG_FULL is not set' out/.config
                fi

                if [[ "$TC" == "GreenForce-Clang" ]]; then
                        sed -i '/-mllvm -regalloc-enable-advisor=release/d' Makefile
                        sed -i '/-mllvm -enable-ml-inliner=release/d' Makefile
                fi

                build_msg
                clearbuild
                makebuild
                zipbuild
                clearbuild

                TOTAL_TIME=$(("$(date +"%s")" - "$START"))

                success_msg
                send_file "out/log.txt"
                send_msg "<b>CI Log Uploaded</b>"
                rm -rf out/log.txt

                uploadbuild

                git restore Makefile arch/arm64/configs/$DEFCONFIG
        ;;

        f )
                rm -rf out
        ;;

        e )
                exit
        ;;
        esac
done
