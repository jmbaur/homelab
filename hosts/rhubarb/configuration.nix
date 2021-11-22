{ config, pkgs, ... }:

let
  promtop = pkgs.callPackage (import (builtins.fetchTarball "https://github.com/jmbaur/promtop/archive/main.tar.gz")) { };
in
{
  # Define that we need to build for ARM, helps with nixops
  nixpkgs.localSystem = {
    system = "aarch64-linux";
    config = "aarch64-unknown-linux-gnu";
  };

  security.sudo.enable = false;

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

  environment.systemPackages = [ promtop ];

  systemd.services.promtop = {
    description = "promtop on tty1";
    serviceConfig = {
      Type = "simple";
      ExecStart = "${promtop}/bin/promtop";
      StandardInput = "tty-force";
      StandardOutput = "tty-force";
      StandardError = "journal";
      TTYPath = "/dev/tty1";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
