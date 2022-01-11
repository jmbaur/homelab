{ writeShellScriptBin }:
writeShellScriptBin "install" ''
  parted /dev/sda -- mklabel msdos
  parted /dev/sda -- mkpart primary 1MiB -2GiB
  parted /dev/sda -- mkpart primary linux-swap -2GiB 100%
  mkfs.ext4 -L nixos /dev/sda1
  mkswap -L swap /dev/sda2
  mount /dev/disk/by-label/nixos /mnt
  swapon /dev/sda2
  nixos-generate-config --root /mnt
  rm /mnt/etc/nixos/configuration.nix
  cp /etc/nixos/bootstrap-configuration.nix /mnt/etc/nixos/configuration.nix
  nixos-install --no-root-passwd
  reboot
''
