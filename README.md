# Homelab

```bash
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB # boot partition
parted /dev/sda -- mkpart primary 512MiB 100% # soon-to-be luks device
parted /dev/sda -- set 1 esp on

cryptsetup luksFormat /dev/sda1
cryptsetup luksOpen /dev/sda1 cryptroot

# Format & mount partitions
mkfs.btrfs -L root /dev/mapper/cryptroot
mkfs.vfat -F 32 -n boot /dev/sda2
mount /dev/mapper/cryptroot /mnt
mkdir -p /mnt/{boot,nix,home,home/.snapshots}
mount /dev/sda2 /mnt/boot
sudo btrfs subvolume create /mnt/@
sudo btrfs subvolume create /mnt/@nix
sudo btrfs subvolume create /mnt/@home
sudo btrfs subvolume create /mnt/@home/.snapshots
sudo umount /dev/mapper/cryptroot
sudo mount -o subvol=@ /dev/mapper/cryptroot /mnt
sudo mount -o subvol=@nix /dev/mapper/cryptroot /mnt/nix
sudo mount -o subvol=@home /dev/mapper/cryptroot /mnt/home
sudo mount -o subvol=@home/.snapshots /dev/mapper/cryptroot /mnt/home/.snapshots

# Generate base NixOS config
nixos-generate-config --root /mnt

# edit /mnt/etc/nixos/hardware-configuration.nix and make sure luks device and subvolumes are present

nixos-install --no-root-passwd # make sure that users.users.<name>.initialPassword is set!

reboot
```
