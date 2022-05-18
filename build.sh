export COMPILER="AzureClang"
export COMPILER_LINK="https://gitlab.com/Panchajanya1999/azure-clang"

export TC_DIR="$HOME/tc/$COMPILER"
export PATH="$TC_DIR/bin:$PATH"

export DEVICE="Poco X3 Pro"
export ZIPNAME="R.Y.N-kernel-vayu-$(date '+%Y%m%d-%H%M').zip"
export DEFCONFIG="vayu_defconfig"

export LAST_COMMIT="$(git log --pretty=format:'"%h : %s"' -1)"
export BRANCH="$(git rev-parse --abbrev-ref HEAD)"
export KBUILD_BUILD_USER="kvsnr113"
export KBUILD_BUILD_HOST="Project113"

export CHATID="-1001586260532"
export TOKEN="5382711200:AAFp0g3MrphAUgylIq8ynMAbfeOys8lzWTI"

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

make O=out ARCH=arm64 $DEFCONFIG

[[ $@ = *"-r"* || $@ = *"--regen"* ]] && {
	cp out/.config arch/arm64/configs/$DEFCONFIG
	exit
}

[[ ! -d "$TC_DIR" ]] && {
	echo "$COMPILER not found! Cloning to $TC_DIR..."
	if ! git clone -q --depth=1 --single-branch "$COMPILER_LINK" "$TC_DIR"; then
		echo "Cloning failed! Aborting..."
		exit 1
	fi
}

[[ ! -d "../AnyKernel3" ]] && {
	echo "AnyKernel3 not found! Cloning to ../AnyKernel3..."
	if ! git clone -q --depth=1 --single-branch "https://github.com/$KBUILD_BUILD_USER/AnyKernel3" ../AnyKernel3; then
		echo "Cloning failed! Aborting..."
		exit 1
	fi
}

send_msg "
Build Triggered !
<b>Device      :</b> <code>$DEVICE</code>
<b>Compiler    :</b> <code>$COMPILER</code>
<b>Branch      :</b> <code>$BRANCH</code>
<b>Last Commit :</b> <code>$LAST_COMMIT</code> "

make -j$(nproc --all) O=out ARCH=arm64 CC=clang LD=ld.lld AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- Image.gz dtbo.img dtb.img | tee out/compile_log.txt

KERNEL="out/arch/arm64/boot/Image.gz"
DTBO="out/arch/arm64/boot/dtbo.img"
DTB="out/arch/arm64/boot/dtb.img"

if [ -f "$KERNEL" ] && [ -f "$DTBO" ] && [ -f "$DTB" ]; then
	cp $KERNEL $DTBO $DTB ../AnyKernel3
	cd ../AnyKernel3 || exit
	zip -r9 "../$ZIPNAME" * -x .git README.md *placeholder
	cd ..
	send_file "@$ZIPNAME" "<b>Build Success -</b><code>$DEVICE</code>"
else
	send_file "@out/compile_log.txt" "<b>Build Failed -</b><code>$DEVICE</code>"
fi
