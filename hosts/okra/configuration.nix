{ config, pkgs, ... }:

let home-manager = import ../misc/home-manager.nix { ref = "release-21.05"; };
in
{
  imports = [ ./hardware-configuration.nix ../common.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = [ "i2c-dev" ];

  networking.hostName = "okra";

  services.udev.extraRules = ''KERNEL=="i2c-[0-9]*", GROUP+="users"'';
  services.openssh.enable = true;
  services.xserver.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}
