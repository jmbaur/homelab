# shellcheck shell=bash

declare -r root_partition="/dev/disk/by-partlabel/root"

declare argc_update_endpoint argc_closure argc_target_disk argc_fstab

# @option --update-endpoint
# @option --closure
# @option --target-disk!
# @option --fstab!

eval "$(argc --argc-eval "$0" "$@")"

target_disk=$(readlink --canonicalize-existing "$argc_target_disk")
fstab=$(readlink --canonicalize-existing "$argc_fstab")
target_mountpoint=$(mktemp -d --suffix="-nixos-recovery")
chmod o+rx "$target_mountpoint"

function cleanup() {
	if umount --recursive "$target_mountpoint" 2>/dev/null; then
		dmsetup remove root 2>/dev/null || true
		rm -rf "$target_mountpoint" || true
	fi
}
trap cleanup EXIT

if [[ -z ${argc_closure:-} ]]; then
	# get the nix output path to our toplevel, used at the end
	toplevel=$(curl \
		--location \
		--silent \
		--fail \
		--write-out "%{stderr}request for toplevel path returned with status %{http_code}\n" \
		--header "Accept: application/json" \
		"$argc_update_endpoint" | jq --raw-output ".buildoutputs.out.path")
else
	toplevel=$argc_closure
fi

# systemd-repart requires a GPT to exist on disk, but we should only touch the
# disk if it isn't already what we are using.
if [[ $(findmnt /nix/.ro-store --output source --noheadings) == "$target_disk"* ]]; then
	echo "Installation media is the same as the target disk, refusing to install"
	exit 1
fi

# partition disks
sector_size=$(blockdev --getss "$target_disk")
systemd-repart --dry-run=no --empty=force --sector-size="$sector_size" "$target_disk"

udevadm wait --timeout=10 "$root_partition"
sleep 2 # TODO(jared): don't do this, though it does appear to be necessary

# unlock root partition
echo "" | cryptsetup open "$root_partition" root

# TODO(jared): mount --all should be able to mount the root filesystem as well?
mount --mkdir --target-prefix="$target_mountpoint" --fstab="$fstab" /
mount --all --mkdir --target-prefix="$target_mountpoint" --fstab="$fstab"

echo "Installing NixOS toplevel $toplevel"

# install toplevel
#
# TODO(jared): why do we need $HOME set?
env HOME="$(mktemp -d)" nixos-install --closure "$toplevel" --root "$target_mountpoint" --no-root-password --no-channel-copy
