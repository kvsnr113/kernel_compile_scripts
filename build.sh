############################### BUILDER SCRIPT ###############################

export TC_DIR="$HOME/tc/compiler"
export PATH="$TC_DIR/bin:$PATH"

export DEVICE="Poco X3 Pro (vayu)"
export ZIPNAME="kernel-vayu-$(date '+%Y%m%d-%H%M').zip"
export DEFCONFIG="vayu_defconfig"

export GITLOG=$(git log --pretty=format:'"%h : %s"' -1)
export KBUILD_BUILD_USER=113
export KBUILD_BUILD_HOST=DonateSerperSar!

export CHATID=-1001586260532
export TOKEN=5382711200:AAFp0g3MrphAUgylIq8ynMAbfeOys8lzWTI

export COMPILER=ProtonClang
export COMPILER_LINK=https://github.com/kdrag0n/proton-clang

curl -s -X POST https://api.telegram.org/bot"${TOKEN}"/sendMessage \
		-d parse_mode="Markdown" \
		-d chat_id="$CHATID" \
		-d text="Building... " 

curl -s -X POST https://api.telegram.org/bot"${TOKEN}"/sendMessage \
		-d parse_mode="Markdown" \
		-d chat_id="$CHATID" \
		-d text="Compiler : $COMPILER || $KBUILD_BUILD_USER-$KBUILD_BUILD_HOST"

curl -s -X POST https://api.telegram.org/bot"${TOKEN}"/sendMessage \
		-d parse_mode="Markdown" \
		-d chat_id="$CHATID" \
		-d text="$GITLOG"

if ! [ -d "$TC_DIR" ]; then
	echo "$COMPILER not found! Cloning to $TC_DIR..."
	if ! git clone -q --depth=1 --single-branch "$COMPILER_LINK" "$TC_DIR"; then
		echo "Cloning failed! Aborting..."
		exit 1
	fi
fi


if [[ $1 = "-r" || $1 = "--regen" ]]; then
	make O=out ARCH=arm64 $DEFCONFIG
	cp out/.config arch/arm64/configs/$DEFCONFIG
	exit
fi

if [[ $1 = "-c" || $1 = "--clean" ]]; then
	rm -rf out
fi

mkdir -p out
make O=out ARCH=arm64 $DEFCONFIG

echo -e "\nStarting compilation...\n"
make -j$(nproc --all) O=out ARCH=arm64 CC=clang LD=ld.lld AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- Image.gz dtbo.img

kernel="out/arch/arm64/boot/Image.gz"
dtb="out/arch/arm64/boot/dts/qcom/sm8150-v2.dtb"
dtbo="out/arch/arm64/boot/dtbo.img"

if [ -f "$kernel" ] && [ -f "$dtb" ] && [ -f "$dtbo" ]; then
	zip -r9 "../$ZIPNAME" $kernel $dtbo $dtb
	cd ..
	curl -F document=@$ZIPNAME https://api.telegram.org/bot"${TOKEN}"/sendDocument \
        -F chat_id="$CHATID" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build Success"
	echo
else
	echo -e "\nCompilation failed!"
	curl -s -X POST https://api.telegram.org/bot"${TOKEN}"/sendMessage \
		-d parse_mode="Markdown" \
		-d chat_id="$CHATID" \
		-d text="Build Failed - $DEVICE"
fi

##############################################################################
