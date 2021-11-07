{ config, pkgs, ... }:



let
  pomtop = pkgs.callPackage
    (import (pkgs.fetchFromGitHub {
      owner = "jmbaur";
      repo = "pomtop";
      rev = "main";
      sha256 = "sha256-YCGxnQuXIFmqOhX8oOGnrt5mbopUDWSYZ12jaEbSPZc=";
    }))
    { };
in

{

  imports = [
    "${
      fetchTarball
      "https://github.com/NixOS/nixos-hardware/archive/936e4649098d6a5e0762058cb7687be1b2d90550.tar.gz"
    }/raspberry-pi/4"
  ];

  # Define that we need to build for ARM, helps with nixops
  nixpkgs.localSystem = {
    system = "aarch64-linux";
    config = "aarch64-unknown-linux-gnu";
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_rpi4;
    tmpOnTmpfs = true;
    initrd.availableKernelModules = [ "usbhid" "usb_storage" ];
    kernelParams =
      [ "8250.nr_uarts=1" "console=ttyAMA0,115200" "console=tty1" "cma=128M" ];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
      raspberryPi = {
        enable = true;
        version = 4;
      };
    };
  };

  hardware = {
    enableRedistributableFirmware = true;
    raspberry-pi."4".fkms-3d.enable = true;
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };

  networking = {
    hostName = "rhubarb";
    interfaces.eth0.useDHCP = true;
  };

  users.mutableUsers = false;

  systemd.services.pomtop = {
    description = "pomtop on tty1";
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pomtop}/bin/pomtop";
      StandardInput = "tty-force";
      StandardOutput = "tty-force";
      TTYPath = "/dev/tty1";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
