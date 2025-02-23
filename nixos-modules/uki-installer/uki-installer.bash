# shellcheck shell=bash

# TODO(jared): support for specialisations

# defined outside of this file
declare boot_loader_timeout can_touch_efi_variables efi_sys_mount_point fwupd_efi ukify_jq enroll_microsoft

workdir=$(mktemp -d)
trap 'rm -rf $workdir' EXIT

declare -a bootctl_flags
bootctl_flags+=("--esp-path=${efi_sys_mount_point}")
if [[ -n $can_touch_efi_variables ]]; then
	bootctl_flags+=("--no-variables")
fi

bootctl install "${bootctl_flags[@]}"

if [[ -n $fwupd_efi ]]; then
	install -D "$fwupd_efi" "${workdir}/${efi_sys_mount_point}/EFI/nixos/$(basename "$fwupd_efi").signed"
fi

new_toplevel=$1

mkdir -p "${workdir}/${efi_sys_mount_point}/EFI/Linux" "${workdir}/${efi_sys_mount_point}/loader"

declare -A generations
while read -r number _generation; do
	toplevel_path=$(readlink --canonicalize-existing "/nix/var/nix/profiles/system-${number}-link")
	generations["$number"]=$toplevel_path
done < <(nix-env --list-generations --profile /nix/var/nix/profiles/system | tac)

declare -a loader_conf_lines

loader_conf_lines+=("timeout ${boot_loader_timeout}")

for generation_number in "${!generations[@]}"; do
	generation=${generations["$generation_number"]}
	uki_filename="nixos-${generation_number}.efi"
	uki="${workdir}/${efi_sys_mount_point}/EFI/Linux/${uki_filename}"
	mapfile -t ukify_args < <(jq --raw-output --from-file "$ukify_jq" <"${generation}/boot.json")
	ukify_args+=("--json=pretty" "--no-sign-kernel" "--output=${uki}")
	ukify build "${ukify_args[@]}"
	if [[ $generation == "$new_toplevel" ]]; then
		loader_conf_lines+=("default ${uki_filename}")
	fi
done

# If no keys exist, create them and enroll them so that the machine can enroll
# them on next boot. The idea is that we will have unique per-device keys that
# will be enrolled during the installation process.
if [[ ! -d /var/lib/sbctl ]]; then
	declare -a sbctl_flags=("--yes-this-might-brick-my-machine" "--export=auth")
	if [[ -n $enroll_microsoft ]]; then
		sbctl_flags+=("--microsoft")
	fi

	sbctl create-keys
	sbctl enroll-keys "${sbctl_flags[@]}"

	install -D --target-directory="${workdir}/${efi_sys_mount_point}/loader/keys/auto" ./*.auth

	loader_conf_lines+=("secure-boot-enroll force")
fi

printf "%s\n" "${loader_conf_lines[@]}" >"${workdir}/${efi_sys_mount_point}/loader/loader.conf"

rm -rf "${efi_sys_mount_point}"/EFI/Linux/*

pushd "$workdir" >/dev/null || exit
while read -r boot_file; do
	install -D "${workdir}/${boot_file}" "/${boot_file}"
done < <(find . -type f -printf "%P\n")
popd >/dev/null || exit

find "$efi_sys_mount_point" -type f -iname '*.efi*' -exec sbctl sign {} \;
