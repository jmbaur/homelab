# shellcheck shell=bash

declare -r root_partition="/dev/disk/by-partlabel/root"

update_endpoint=$1
target_disk=$(readlink --canonicalize "$2")
fstab=$(readlink --canonicalize "$3")

function error_handler() {
	umount --recursive /mnt 2>/dev/null || true
	dmsetup remove root 2>/dev/null || true
}
trap error_handler ERR

# get the nix output path to our toplevel, used at the end
toplevel=$(curl \
	--location \
	--silent \
	--fail \
	--write-out "%{stderr}request for toplevel path returned with status %{http_code}\n" \
	--header "Accept: application/json" \
	"$update_endpoint" | jq --raw-output ".buildoutputs.out.path")

# systemd-repart requires a GPT to exist on disk, but we should only touch the
# disk if it isn't already what we are using.
if [[ $(findmnt /nix/.ro-store --output source --noheadings) != "$target_disk"* ]]; then
	echo "label: gpt" | sfdisk --wipe=always "$target_disk"
fi

# partition disks
sector_size=$(blockdev --getss "$target_disk")
systemd-repart --dry-run=no --factory-reset=yes --sector-size="$sector_size" "$target_disk"

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
