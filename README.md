# Homelab

## Generic install guide

```bash
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB # boot partition
parted /dev/sda -- mkpart primary 512MiB 100% # soon-to-be luks device
parted /dev/sda -- set 1 esp on

cryptsetup luksFormat /dev/sda2
cryptsetup luksOpen /dev/sda2 cryptroot

# Format & mount partitions
mkfs.btrfs -L root /dev/mapper/cryptroot
mkfs.vfat -F 32 -n boot /dev/sda1
mount /dev/mapper/cryptroot /mnt
mkdir -p /mnt/{boot,nix,home,home/.snapshots}
mount /dev/sda1 /mnt/boot
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@home/.snapshots
umount /dev/mapper/cryptroot
mount -o subvol=@ /dev/mapper/cryptroot /mnt
mount -o subvol=@nix /dev/mapper/cryptroot /mnt/nix
mount -o subvol=@home /dev/mapper/cryptroot /mnt/home
mount -o subvol=@home/.snapshots /dev/mapper/cryptroot /mnt/home/.snapshots

# Generate base NixOS config
nixos-generate-config --root /mnt

# edit /mnt/etc/nixos/hardware-configuration.nix and make sure luks device and subvolumes are present

nixos-install --no-root-passwd # make sure that users.users.<name>.hashedPassword is set!

reboot
```

## Yubikey

To require a touch of the Yubikey when using its smart card functionality:
`ykman openpgp keys set-touch sig cached-fixed`

## RouterOS

Configuration changes involve a reset of the device.

```rascal
/system reset-configuration no-defaults=yes run-after-reset=flash/restore.rsc
```
