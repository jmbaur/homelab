{ config, lib, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda";

  networking.hostName = "kodi";
  networking.useDHCP = false;
  networking.interfaces.ens18.useDHCP = true;
  networking.firewall.allowedTCPPorts = [ 2049 ];

  services.qemuGuest.enable = true;

  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /kodi *
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
