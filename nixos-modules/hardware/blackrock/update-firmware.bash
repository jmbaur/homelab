# shellcheck shell=bash

declare esp capsule capsule_app uefi_shell fw_class fw_version

# Linux can't call UpdateCapsule or write EFI variables since runtime services
# are disabled (efi=noruntime), so the capsule is applied from the UEFI shell
# with CapsuleApp.efi. Without EFI variables, `bootctl set-oneshot` can't be
# used either. Instead, loader.conf is pointed at an entry for the shell, and
# startup.nsh restores the original loader.conf before applying the capsule,
# making it a one-shot boot regardless of whether the update succeeds.

esrt_entry=
for entry in /sys/firmware/efi/esrt/entries/*; do
	if [[ $(<"$entry/fw_class") == "$fw_class" ]]; then
		esrt_entry=$entry
		break
	fi
done

if [[ -z $esrt_entry ]]; then
	echo "no ESRT entry found for $fw_class"
	exit 1
fi

current_version=$(<"$esrt_entry/fw_version")
if ((current_version >= fw_version)) && [[ ${1:-} != "--force" ]]; then
	echo "firmware is up to date (version $current_version), use --force to apply anyway"
	exit 0
fi

dir=${esp}/EFI/firmware-update

rm -rf "$dir"
mkdir -p "$dir"
install -m0644 "$uefi_shell" "${dir}/shell.efi"
install -m0644 "$capsule_app" "${dir}/CapsuleApp.efi"
install -m0644 "$capsule" "${dir}/capsule.bin"
cp "${esp}/loader/loader.conf" "${dir}/loader.conf"

# The shell runs startup.nsh from the directory it was launched from.
# %homefilesystem% is the filesystem the shell was launched from. CapsuleApp
# resets the machine once the capsule is submitted, so the trailing reset only
# runs if it fails.
cat >"${dir}/startup.nsh" <<'EOF'
@echo -off
%homefilesystem%
cd \EFI\firmware-update
cp -q loader.conf \loader\loader.conf
rm -q \loader\entries\firmware-update.conf
CapsuleApp.efi capsule.bin
reset
EOF

cat >"${esp}/loader/entries/firmware-update.conf" <<EOF
title Firmware update
efi /EFI/firmware-update/shell.efi
EOF

sed -i '/^default /d' "${esp}/loader/loader.conf"
echo "default firmware-update.conf" >>"${esp}/loader/loader.conf"

sync --file-system "$esp"

echo "firmware update staged (version $current_version -> $fw_version), reboot to apply"
