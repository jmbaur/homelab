{ writeShellScriptBin }:
writeShellScriptBin "install" ''
  sudo parted /dev/sda -- mklabel msdos
  sudo parted /dev/sda -- mkpart primary 1MiB -2GiB
  sudo parted /dev/sda -- mkpart primary linux-swap -2GiB 100%
  sudo mkfs.ext4 -L nixos /dev/sda1
  sudo mkswap -L swap /dev/sda2
  sudo mount /dev/disk/by-label/nixos /mnt
  sudo swapon /dev/sda2
  sudo nixos-generate-config --root /mnt
  sudo rm /mnt/etc/nixos/configuration.nix
  sudo cp /etc/nixos/bootstrap-configuration.nix /mnt/etc/nixos/configuration.nix
  sudo nixos-install --no-root-passwd
  sudo reboot
''
