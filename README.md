# Homelab

```bash
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart primary 512MiB 100% # soon-to-be luks device
parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB # boot partition
parted /dev/sda -- set 2 esp on

cryptsetup luksFormat /dev/sda1 # use key file to create luks device
cryptsetup luksOpen /dev/sda1 cryptlvm # use key file to open luks device

# LVM stuff
pvcreate /dev/mapper/cryptlvm
vgcreate vg /dev/mapper/cryptlvm
lvcreate -L 8G -n swap vg # create 8GB swap space
lvcreate -l '100%FREE' -n root vg # use rest for root

# Format & mount partitions
mkfs.ext4 -L root /dev/vg/root
mkswap -L swap /dev/vg/swap
mkfs.vfat -F 32 -n boot /dev/sda2
mount /dev/vg/root /mnt
mkdir /mnt/boot
mount /dev/sda2 /mnt/boot
swapon /dev/vg/swap # optional

# Generate base NixOS config
nixos-generate-config --root /mnt

# NixOS stuff
uuid=$(blkid -s UUID /dev/sda1 | cut -d\" -f2)
echo << EOF
# Put this in your /etc/nixos/hardware-configuration.nix
services.udev.packages = [ pkgs.yubikey-personalization ];
boot.initrd.luks.devices.cryptlvm = {
  allowDiscards = true;
  device = "/dev/disk/by-uuid/${uuid}";
  preLVM = true;
};
EOF
nixos-install --no-root-passwd # make sure that users.users.<name>.initialPassword is set!
reboot
```
