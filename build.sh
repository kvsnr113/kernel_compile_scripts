export TC_DIR="../clang"
export PATH="$TC_DIR/bin:$PATH"

export DEVICE="Poco X3 Pro"
export ZIPNAME="R.Y.N-kernel-vayu-$(date '+%Y%m%d-%H%M').zip"
export DEFCONFIG="vayu_defconfig"

export LAST_COMMIT="$(git log --pretty=format:'"%h : %s"' -1)"
export BRANCH="$(git rev-parse --abbrev-ref HEAD)"
export KBUILD_BUILD_USER="kvsnr113"
export KBUILD_BUILD_HOST="Project113"
export CPU="$(neofetch | grep 'CPU' | awk -F ':' '{print $2}')"
export MEMTOTAL="$(awk '/MemTotal/ {printf( "%d\n", $2 / 1024 )}' /proc/meminfo)"
export MEMFREE="$(awk '/MemFree/ {printf( "%d\n", $2 / 1024 )}' /proc/meminfo)"

export CHATID="-1001586260532"
export TOKEN="5382711200:AAFp0g3MrphAUgylIq8ynMAbfeOys8lzWTI"

build_kernel(){
        rm -rf ../log.txt
        touch ../log.txt
        [[ ! -d "../AnyKernel3" ]] && {
                echo "AnyKernel3 not found! Cloning to AnyKernel3..."
                if ! git clone -q --depth=1 --single-branch "https://github.com/$KBUILD_BUILD_USER/AnyKernel3" ../AnyKernel3; then
                        echo "Cloning failed! Aborting..."
                        exit 1
                fi
        }

        make O=out ARCH=arm64 $DEFCONFIG
        make -j$(nproc --all) \
            O=out \
            ARCH=arm64 \
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
            CROSS_COMPILE=aarch64-linux-gnu- \
            CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
            Image.gz dtbo.img

        KERNEL="out/arch/arm64/boot/Image.gz"
        DTBO="out/arch/arm64/boot/dtbo.img"
        DTB="out/arch/arm64/boot/dts/qcom/sm8150-v2.dtb"

        if [ -f "$KERNEL" ] && [ -f "$DTBO" ] && [ -f "$DTB" ]; then
                cp $KERNEL $DTBO $DTB ../AnyKernel3
                mv ../AnyKernel3/sm8150-v2.dtb ../AnyKernel3/dtb
                cd ..
                cd AnyKernel3
                zip -r9 "../$ZIPNAME" * -x .git README.md *placeholder
                cd ..
                send_file "$ZIPNAME" "Build Success"
        else
                send_msg "Build Failed"
        fi

        send_file "log.txt" "Build Log"
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

[[ $@ = *"-c"* || $@ = *"--clean"* ]] && rm -rf out

[[ $@ = *"-r"* || $@ = *"--regen"* ]] && {
        make O=out ARCH=arm64 $DEFCONFIG
        cp out/.config arch/arm64/configs/$DEFCONFIG
        exit
}

[[ $@ = *"-b"* || $@ = *"--build"* ]] && {
send_msg "
<b>Build Triggered !</b>
<b>Builder :</b>
<b>CPU</b><code>$CPU</code>
<b>RAM</b> <code>Total $MEMTOTAL Mb | Free $MEMFREE Mb </code>
<b>==================================</b>
<b>Branch :</b> <code>$BRANCH</code>
<b>Last Commit :</b> <code>$LAST_COMMIT</code>
<b>==================================</b>"
build_kernel 2>&1 | tee ../log.txt
}
