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

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  networking = {
    hostName = "rhubarb";
    domain = "home.arpa";
    nameservers = singleton "192.168.88.1";
    defaultGateway.address = "192.168.88.1";
    defaultGateway.interface = "eth0";
    interfaces.eth0 = {
      useDHCP = false;
      ipv4.addresses = [{
        address = "192.168.88.88";
        prefixLength = 24;
      }];
      ipv6.addresses = [{
        address = "fd82:f21d:118d:58::58";
        prefixLength = 64;
      }];
    };
  };
}
