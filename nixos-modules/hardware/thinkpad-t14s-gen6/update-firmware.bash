# shellcheck shell=bash

declare esp

firmware_update_utility=${1:-}

if [[ -z $firmware_update_utility ]]; then
	echo "no firmware update utility file provided"
	exit 1
fi

firmware_update_utility=$(realpath "$firmware_update_utility")

out=$(mktemp -d)
trap 'rm -rf $out' EXIT
pushd "$out" >/dev/null || exit 1
innoextract --output-dir out "$firmware_update_utility"

install -Dv ./out/*/Rfs/Usb/Bootaa64.efi "${esp}/EFI/Lenovo/update.efi"
cp -r out/*/Rfs/Fw/* "${esp}/Flash/"

bootctl set-oneshot /EFI/Lenovo/update.efi
