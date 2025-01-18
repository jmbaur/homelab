# shellcheck shell=bash

declare -r root_partition="/dev/disk/by-partlabel/root"

updateEndpoint=$1
targetDisk=$(realpath "$2")
fstab=$(realpath "$3")

function error_handler() {
	umount --recursive /mnt 2>/dev/null || true
	dmsetup remove root 2>/dev/null || true
}
trap error_handler ERR

# TODO(jared): wait for network to be up

# get the nix output path to our toplevel, used at the end
toplevel=$(curl --silent --fail "$updateEndpoint")

# systemd-repart requires a GPT to exist on disk, but we should only touch the
# disk if it isn't already what we are using.
if [[ $(findmnt /nix/store --output source --noheadings) != "$targetDisk"* ]]; then
	echo "label: gpt" | sfdisk --wipe=always "$targetDisk"
fi

# partition disks
systemd-repart --dry-run=no --factory-reset=yes "$targetDisk"

udevadm wait --timeout=10 "$root_partition"
sleep 2 # TODO(jared): don't do this, though it does appear to be necessary

# unlock root partition
echo "" | cryptsetup open "$root_partition" root

# mount all filesystems needed for performing the installation
#
# TODO(jared): we should be able to use `mount --all` here
for mountpoint in "/" "/boot"; do
	mount --target-prefix=/mnt --options X-mount.mkdir --fstab="$fstab" "$mountpoint"
done

# install toplevel
#
# TODO(jared): why do we need $HOME set?
env HOME="$(mktemp -d)" nixos-install --closure "$toplevel" --root /mnt --no-root-password --no-channel-copy

systemctl reboot
