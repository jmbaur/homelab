# shellcheck shell=bash

export DISK="/dev/nvme0n1"

blkdiscard $DISK

export BOOT_PART="${DISK}p1"
export CRYPT_PART="${DISK}p2"

parted $DISK -- mklabel gpt
parted $DISK -- mkpart ESP fat32 1MiB 512MiB
parted $DISK -- mkpart primary 512MiB 100%
parted $DISK -- set 1 esp on

cryptsetup luksFormat $CRYPT_PART
cryptsetup luksOpen $CRYPT_PART cryptroot
systemd-cryptenroll --fido2-device=auto $CRYPT_PART

mkfs.btrfs /dev/mapper/cryptroot
mkfs.vfat -F32 $BOOT_PART
mount /dev/mapper/cryptroot /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@home
umount /mnt

mount -o X-mount.mkdir,subvol=@,discard=async,compress=zstd,noatime /dev/mapper/cryptroot /mnt
mount -o X-mount.mkdir,subvol=@nix,discard=async,compress=zstd,noatime /dev/mapper/cryptroot /mnt/nix
mount -o X-mount.mkdir,subvol=@home,discard=async,compress=zstd,noatime /dev/mapper/cryptroot /mnt/home
mount -o X-mount.mkdir $BOOT_PART /mnt/boot

nixos-generate-config --root /mnt --show-hardware-config >nixosConfigurations/beetroot/hardware-configuration.nix

ssh-keygen -t ed25519 -N "" -f /mnt/etc/ssh/ssh_host_ed25519_key
ssh-keygen -t rsa -b 4096 -N "" -f /mnt/etc/ssh/ssh_host_rsa_key

new_age_public_key=$(ssh-to-age </etc/ssh/ssh_host_ed25519_key.pub) \
	yq -i '(.keys[] | select(anchor=="beetroot")) = strenv(new_age_public_key)' .sops.yaml

sops updatekeys nixosConfigurations/beetroot/secrets.yaml

nixos-install --flake .#beetroot --no-root-password

# needed for the sops-nix portion of the activation script to write to /etc/shadow.
nixos-enter --command "echo done!"
