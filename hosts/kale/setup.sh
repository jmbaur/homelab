#!/usr/bin/env bash

set -e

parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart primary 512MiB -8GiB
parted /dev/nvme0n1 -- mkpart primary linux-swap -8GiB 100%
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 512MiB
parted /dev/nvme0n1 -- set 3 esp on
mkfs.ext4 -L nixos /dev/nvme0n1p1
mkswap -L swap /dev/nvme0n1p2
mkfs.fat -F 32 -n boot /dev/nvme0n1p3

parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart primary 1MiB 100%

parted /dev/sdb -- mklabel gpt
parted /dev/sdb -- mkpart primary 1MiB 100%

mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sda1 /dev/sdb1
mkfs.ext4 -L data /dev/md0

mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
mkdir -p /mnt/data
mount /dev/disk/by-label/data /mnt/data
swapon /dev/nvme0n1p2

nixos-generate-config --root /mnt
vim /mnt/etc/nixos/configuration.nix
nixos-install
reboot
