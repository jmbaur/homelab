# shellcheck shell=bash

disk="/dev/mmcblk0"
# kernel1="${disk}p1"
# kernel2="${disk}p2"
root="${disk}p3"

blkdiscard --force "$disk"

parted "$disk" -- mklabel gpt
parted "$disk" -- mkpart primary 1MiB 64MiB   # primary kernel partition
parted "$disk" -- mkpart primary 65MiB 128MiB # backup kernel partition
parted "$disk" -- mkpart primary 129MiB 100%  # root partition

# TODO(jared): change partition type GUIDs

cgpt add -t kernel -i 1 -S 1 -T 5 -P 10 "$disk"

mount "$root" /mnt
nixos-install --flake github:jmbaur/homelab#fennel --root /mnt --no-root-passwd
