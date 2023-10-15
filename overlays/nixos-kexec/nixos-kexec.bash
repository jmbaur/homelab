# shellcheck shell=bash

choices=()

for profile in $(find /nix/var/nix/profiles -type l -name "system-*" | sort); do
	system_name=$(basename "$profile")
	label=$(jq --raw-output '."org.nixos.bootspec.v1".label' <"${profile}/boot.json")
	for specialisation in $(find "$profile"/specialisation -type l | sort); do
		specialisation_name=$(basename "$specialisation")
		label=$(jq --raw-output '."org.nixos.bootspec.v1".label' <"${profile}/boot.json")
		choices+=("${system_name}/specialisation/${specialisation_name}: ${label}")
	done
	choices+=("${system_name}: ${label}")
done

choice=$(printf "%s\n" "${choices[@]}" | sk --no-sort --tac --reverse | cut -d':' -f1)

eval "$(jq --raw-output '."org.nixos.bootspec.v1" | "sudo kexec -l \(.kernel) --initrd=\(.initrd) --command-line=\"init=\(.init) \(.kernelParams | join(" "))\""' <"/nix/var/nix/profiles/${choice}/boot.json") $*"

echo "Kexec loaded, run 'systemctl kexec' to finish kexec"
