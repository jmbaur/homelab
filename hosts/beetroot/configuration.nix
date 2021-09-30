{ config, pkgs, ... }:
{
  imports = [
    ../../lib/common.nix
    ./hardware-configuration.nix
  ];

  hardware.cpu.amd.updateMicrocode = true;

  networking.hostName = "beetroot";

  hardware.bluetooth.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  programs.mtr.enable = true;

  services.xserver.libinput = {
    enable = true;
    touchpad = {
      accelProfile = "flat";
      tapping = true;
      naturalScrolling = true;
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}
