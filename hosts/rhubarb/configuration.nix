{ config, lib, pkgs, ... }:
with lib;
{
  custom.common.enable = true;
  custom.deploy.enable = true;

  zramSwap = {
    enable = true;
    swapDevices = 1;
  };

  hardware.raspberry-pi."4".fkms-3d.enable = true;
  hardware.raspberry-pi."4".audio.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.bluetooth.enable = true;

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  time.timeZone = "America/Los_Angeles";
  networking = {
    hostName = "rhubarb";
    domain = "home.arpa";
    nameservers = singleton "192.168.20.1";
    defaultGateway.address = "192.168.20.1";
    defaultGateway.interface = "eth0";
    wireless.enable = true;
    wireless.interfaces = singleton "wlan0";
    interfaces.wlan0.useDHCP = true;
    interfaces.eth0 = {
      useDHCP = false;
      ipv4.addresses = [{
        address = "192.168.20.50";
        prefixLength = 24;
      }];
    };
    firewall.allowedTCPPorts = [ 8080 ];
    firewall.allowedUDPPorts = [ 8080 ];
  };

  services.avahi = {
    enable = true;
    publish.enable = true;
    publish.userServices = true;
  };

  services.spotifyd = {
    enable = true;
    settings = {
      username = "5hwn4ipbrmdi9z3vmkerzoh6n";
      backend = "pulseaudio";
      device = "default";
    };
  };

  users.users.kodi.isNormalUser = true;
  services.cage = {
    enable = true;
    user = "kodi";
    program = "${pkgs.kodi-wayland}/bin/kodi-standalone";
  };

}
