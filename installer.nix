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
  cat | sudo tee /mnt/etc/nixos/configuration.nix << EOF
{ config, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda";
  networking.useDHCP = false;
  networking.interfaces.ens18.useDHCP = true;
  users.users.root.openssh.authorizedKeys.keyFiles = [
    (builtins.fetchurl {
      url = "https://github.com/jmbaur.keys";
      sha256 = "1w3f101ri4rf0d98zf4zcdc5i0nv29mcz39p558l5r38p2s7nbrm";
    })
  ];
  environment.systemPackages = with pkgs; [ vim ];
  services.openssh.enable = true;
  services.qemuGuest.enable = true;
}
EOF
  sudo nixos-install --no-root-passwd
  sudo reboot
''
