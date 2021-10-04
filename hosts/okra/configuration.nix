{ config, pkgs, ... }:

let
  nixos-hardware = builtins.fetchTarball "https://github.com/nixos/nixos-hardware/archive/master.tar.gz";
in
{
  imports =
    [
      ./hardware-configuration.nix
      ../../lib/common.nix
      "${nixos-hardware}/common/cpu/amd"
      "${nixos-hardware}/common/pc/ssd"
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    extraModulePackages = with config.boot.kernelPackages; [ ddcci-driver ];
    kernelModules = [ "i2c-dev" ];
  };
  services.udev.extraRules = ''KERNEL=="i2c-[0-9]*", GROUP+="users"'';

  environment.systemPackages = [ pkgs.ddcutil ];

  networking.hostName = "okra";

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

