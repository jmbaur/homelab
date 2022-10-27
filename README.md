# Homelab

## Generic install guide

```bash
export DISK="/dev/sda"
export BOOT_PART="${DISK}1"
export CRYPT_PART="${DISK}2"

parted $DISK -- mklabel gpt
parted $DISK -- mkpart ESP fat32 1MiB 512MiB # boot partition
parted $DISK -- mkpart primary 512MiB 100% # encrypted partition
parted $DISK -- set 1 esp on

cryptsetup luksFormat $CRYPT_PART
cryptsetup luksOpen $CRYPT_PART cryptroot
systemd-cryptenroll --fido2-device=auto $CRYPT_PART

# Format & mount partitions
mkfs.btrfs -L root /dev/mapper/cryptroot
mkfs.vfat -F 32 -n boot $BOOT_PART
mount /dev/mapper/cryptroot /mnt
mkdir -p /mnt/{boot,nix,home,home/.snapshots}
mount $BOOT_PART /mnt/boot
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@home
umount /dev/mapper/cryptroot
mount -o subvol=@ /dev/mapper/cryptroot /mnt
mount -o subvol=@nix /dev/mapper/cryptroot /mnt/nix
mount -o subvol=@home /dev/mapper/cryptroot /mnt/home

# Generate base NixOS config
nixos-generate-config --root /mnt

# edit /mnt/etc/nixos/hardware-configuration.nix and make sure luks device and subvolumes are present

nixos-install --no-root-passwd # make sure that users.users.<name>.hashedPassword is set!

reboot
```
