# shellcheck shell=bash

disk="/dev/mmcblk0"
# kernel1="${disk}p1"
# kernel2="${disk}p2"
root="${disk}p3"
cryptroot="/dev/mapper/cryptroot"

blkdiscard --force "$disk"

parted "$disk" -- mklabel gpt
parted "$disk" -- mkpart primary 1MiB 64MiB   # primary kernel partition
parted "$disk" -- mkpart primary 65MiB 128MiB # backup kernel partition
parted "$disk" -- mkpart primary 129MiB 100%  # root partition

# TODO(jared): change partition type GUIDs

cgpt add -t kernel -i 1 -S 1 -T 5 -P 10 "$disk"

cryptsetup luksFormat "$root"
cryptsetup luksOpen "$root" cryptroot
systemd-cryptenroll --fido2-device=auto "$root"

mkfs.btrfs "$cryptroot"
mount "$cryptroot" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@home
umount /mnt

# TODO(jared): verify if mmc devices can do trimming
mount -o X-mount.mkdir,subvol=@,noatime,discard=async,compress=zstd "$cryptroot" /mnt
mount -o X-mount.mkdir,subvol=@nix,noatime,discard=async,compress=zstd "$cryptroot" /mnt/nix
mount -o X-mount.mkdir,subvol=@home,noatime,discard=async,compress=zstd "$cryptroot" /mnt/home

nixos-install --flake github:jmbaur/homelab#fennel --root /mnt --no-root-passwd
