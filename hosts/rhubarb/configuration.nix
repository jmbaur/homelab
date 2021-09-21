{ config, lib, pkgs, ... }: {
  imports = [
    "${
      fetchTarball
      "https://github.com/NixOS/nixos-hardware/archive/936e4649098d6a5e0762058cb7687be1b2d90550.tar.gz"
    }/raspberry-pi/4"
  ];

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
        firmwareConfig = ''
          dtparam=audio=on
        '';
      };
    };
  };

  hardware = {
    enableRedistributableFirmware = true;
    raspberry-pi."4".fkms-3d.enable = true;
    pulseaudio.enable = true;
    bluetooth.enable = true;
  };

  sound.enable = true;

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };

  # fileSystems."/data/kodi" = {
  #   device = "kale.lan:/kodi";
  #   fsType = "nfs";
  #   options = [ "x-systemd.automount" "noauto" ];
  # };

  networking = {
    hostName = "rhubarb";
    wireless.iwd.enable = true;
    interfaces.eth0.useDHCP = true;
    firewall = {
      allowedTCPPorts = [ 8080 ];
      allowedUDPPorts = [ 8080 ];
    };
  };

  users.extraUsers.kodi.isNormalUser = true;

  services = {
    openssh.enable = true;
    xserver = {
      enable = true;
      desktopManager.kodi.enable = true;
      displayManager = {
        autoLogin.enable = true;
        autoLogin.user = "kodi";
      };
    };
    avahi = {
      enable = true;
      publish.enable = true;
      publish.userServices = true;
    };
  };
}
