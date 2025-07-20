# shellcheck shell=bash

declare keyblock vbprivk fitimage_its

toplevel=$1
dtb=${2:-}
out=$PWD

tmpdir=$(mktemp -d)
trap 'rm -rf $tmpdir' EXIT
pushd "$tmpdir" >/dev/null || exit 1

lzma --threads=0 <"$(jq --raw-output '."org.nixos.bootspec.v1"."kernel"' "${toplevel}/boot.json")" >kernel.lzma
cp "$(jq --raw-output '."org.nixos.bootspec.v1"."initrd"' "${toplevel}/boot.json")" initrd
if [[ -n $dtb ]]; then
	cp "$dtb" fdt
fi

cp "$fitimage_its" fitimage.its # needs to be in the same directory
mkimage -D "-I dts -O dtb -p 2048" -f fitimage.its vmlinux.uimg

dd status=none if=/dev/zero of=bootloader.bin bs=512 count=1

jq --raw-output "\"init=\(.\"org.nixos.bootspec.v1\".init) \(.\"org.nixos.bootspec.v1\".kernelParams | join(\" \"))\"" <"${toplevel}/boot.json" >kernel-params

futility vbutil_kernel \
	--pack kpart \
	--version 1 \
	--vmlinuz vmlinux.uimg \
	--arch aarch64 \
	--keyblock "$keyblock" \
	--signprivate "$vbprivk" \
	--config kernel-params \
	--bootloader bootloader.bin

dd status=none if=/dev/zero of=chromeos-image.raw bs=4M count=20
sfdisk --no-reread --no-tell-kernel chromeos-image.raw <<EOF
label: gpt
label-id: A8ABB0FA-2FD7-4FB8-ABB0-2EEB7CD66AFA
size=64m, type=FE3A2A5D-4F32-41A7-B725-ACCC3285A309, uuid=534078AF-3BB4-EC43-B6C7-828FB9A788C6, name=kernel
EOF
cgpt add -i 1 -S 1 -T 5 -P 10 chromeos-image.raw
eval "$(partx chromeos-image.raw -o START,SECTORS --nr 1 --pairs)"
dd status=none conv=notrunc if=kpart of=chromeos-image.raw seek="$START" count="$SECTORS"
cp chromeos-image.raw "${out}/chromeos-image.raw"
