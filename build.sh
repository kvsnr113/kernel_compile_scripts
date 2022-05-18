export COMPILER=AzureClang
export COMPILER_LINK=https://gitlab.com/Panchajanya1999/azure-clang

export TC_DIR="$HOME/tc/$COMPILER"
export PATH="$TC_DIR/bin:$PATH"

export DEVICE="Poco X3 Pro"
export ZIPNAME="R.Y.N-kernel-vayu-$(date '+%Y%m%d-%H%M').zip"
export DEFCONFIG="vayu_defconfig"

export GITLOG=$(git log --pretty=format:'"%h : %s"' -1)
export KBUILD_BUILD_USER=kvsnr113
export KBUILD_BUILD_HOST=Project113

export CHATID=-1001586260532
export TOKEN=5382711200:AAFp0g3MrphAUgylIq8ynMAbfeOys8lzWTI

sudo apt install cpio

curl -s -X POST https://api.telegram.org/bot"${TOKEN}"/sendMessage \
		-d parse_mode="Markdown" \
		-d chat_id="$CHATID" \
		-d text="Building... " 

curl -s -X POST https://api.telegram.org/bot"${TOKEN}"/sendMessage \
		-d parse_mode="Markdown" \
		-d chat_id="$CHATID" \
		-d text="Device : $DEVICE || Compiler : $COMPILER || Builder : $KBUILD_BUILD_USER-$KBUILD_BUILD_HOST"

curl -s -X POST https://api.telegram.org/bot"${TOKEN}"/sendMessage \
		-d parse_mode="Markdown" \
		-d chat_id="$CHATID" \
		-d text="$GITLOG"

[[ $@ = *"-c"* || $@ = *"--clean"* ]] && rm -rf out

[[ ! -d "$TC_DIR" ]] && {
	echo "$COMPILER not found! Cloning to $TC_DIR..."
	if ! git clone -q --depth=1 --single-branch "$COMPILER_LINK" "$TC_DIR"; then
		echo "Cloning failed! Aborting..."
		exit 1
	fi
}

[[ ! -d "AnyKernel3" ]] && {
	echo "AnyKernel3 not found! Cloning to AnyKernel3..."
	if ! git clone -q --depth=1 --single-branch "https://github.com/$KBUILD_BUILD_USER/AnyKernel3"; then
		echo "Cloning failed! Aborting..."
		exit 1
	fi
}

make O=out ARCH=arm64 $DEFCONFIG

[[ $@ = *"-r"* || $@ = *"--regen"* ]] && {
	cp out/.config arch/arm64/configs/$DEFCONFIG
	exit
}

make -j$(nproc --all) O=out ARCH=arm64 CC=clang LD=ld.lld AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- Image.gz dtbo.img dtb.img

KERNEL="out/arch/arm64/boot/Image.gz"
DTBO="out/arch/arm64/boot/dtbo.img"
DTB="out/arch/arm64/boot/dtb.img"

if [ -f "$kernel" ] && [ -f "$dtbo" ] && [ -f "$dtb" ]; then
	echo -e "\nKernel compiled succesfully! Zipping up...\n"
	cp $KERNEL $DTBO $DTB AnyKernel3
	cd AnyKernel3 || exit
	zip -r9 "../$ZIPNAME" * -x .git README.md *placeholder
	cd ..
	curl -F document=@$ZIPNAME https://api.telegram.org/bot"${TOKEN}"/sendDocument \
        -F chat_id="$CHATID" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build Success - $DEVICE"
	echo
else
	curl -s -X POST https://api.telegram.org/bot"${TOKEN}"/sendMessage \
		-d parse_mode="Markdown" \
		-d chat_id="$CHATID" \
		-d text="Build Failed - $DEVICE"
fi
