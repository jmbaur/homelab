# shellcheck shell=bash

# TODO(jared): support for specialisations

# defined outside of this file
declare boot_loader_timeout can_touch_efi_variables efi_sys_mount_point fwupd_efi ukify_jq

workdir=$(mktemp -d)
trap 'rm -rf $workdir' EXIT

declare -a bootctl_flags
bootctl_flags+=("--esp-path=${efi_sys_mount_point}")
if [[ -n $can_touch_efi_variables ]]; then
	bootctl_flags+=("--no-variables")
fi

if bootctl is-installed >/dev/null; then
	bootctl update "${bootctl_flags[@]}"
else
	bootctl install "${bootctl_flags[@]}"
fi

if [[ -n $fwupd_efi ]]; then
	install -D "$fwupd_efi" "${efi_sys_mount_point}/EFI/nixos/$(basename "$fwupd_efi")"
fi

new_toplevel=$1

mkdir -p "${workdir}/${efi_sys_mount_point}/EFI/Linux" "${workdir}/${efi_sys_mount_point}/loader"

declare -A generations
while read -r number _generation; do
	toplevel_path=$(readlink --canonicalize "/nix/var/nix/profiles/system-${number}-link")
	generations["$number"]=$toplevel_path
done < <(nix-env --list-generations --profile /nix/var/nix/profiles/system | tac)

declare -a loader_conf_lines

loader_conf_lines+=("timeout ${boot_loader_timeout}")
loader_conf_lines+=("editor yes")

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

rm -rf "${efi_sys_mount_point}"/EFI/Linux/*

pushd "$workdir" >/dev/null || exit
while read -r boot_file; do
	mkdir -p "$(dirname "$boot_file")"
	install "${workdir}/${boot_file}" "/${boot_file}"
done < <(find . -type f -printf "%P\n")
popd >/dev/null || exit

printf "%s\n" "${loader_conf_lines[@]}" >"${efi_sys_mount_point}/loader/loader.conf"

find "$efi_sys_mount_point" -type f -iname '*.efi' -exec sbctl sign {} \;
