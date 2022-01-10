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
