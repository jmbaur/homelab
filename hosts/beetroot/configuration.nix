{ config, pkgs, ... }:
let
  nixos-hardware = builtins.fetchTarball "https://github.com/nixos/nixos-hardware/archive/master.tar.gz";
in
{
  imports = [
    ./hardware-configuration.nix
    ../../lib/common.nix
    ../../lib/desktop.nix
    ../../lib/dev.nix
    "${nixos-hardware}/lenovo/thinkpad/t495"
    "${nixos-hardware}/common/pc/ssd"
  ];

  boot.initrd.luks = {
    gpgSupport = true;
    devices.cryptlvm = {
      allowDiscards = true;
      device = "/dev/disk/by-uuid/25d5e7ed-7def-408f-922b-41ecf319e19b";
      preLVM = true;
      gpgCard = {
        publicKey = ../../lib/pgp_keys.asc;
        encryptedPass = ./disk.key.gpg;
        gracePeriod = 30;
      };
    };
  };

  # TLP causing issues with USB ports turning off. Override TLP set from
  # https://github.com/NixOS/nixos-hardware/blob/master/common/pc/laptop/default.nix
  services.power-profiles-daemon.enable = true;

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
