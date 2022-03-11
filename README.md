# Homelab

## TODO

Write an activation script (`system.activationScript`) to create directories
for bind mounts that NixOS containers use that do not yet exist.

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

nixos-install --no-root-passwd # make sure that users.users.<name>.initialPassword is set!

reboot
```

## Libvirt

To use a bridge device which gives a VM guest direct access to the host's
network:

https://libvirt.org/formatnetwork.html#examplesBridge
