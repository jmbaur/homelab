{ config, lib, pkgs, ... }:
let
  mgmt-iface = "eno1";
  mgmt-address = "192.168.88.4";
  mgmt-network = "192.168.88.0";
  mgmt-gateway = "192.168.88.1";
  mgmt-netmask = "255.255.255.0";
  mgmt-prefix = 24;
in
with lib;
{
  imports = [ ./hardware-configuration.nix ];

  boot.kernelPackages = pkgs.linuxPackages_5_15;
  boot.kernelParams = [
    "ip=${mgmt-address}::${mgmt-gateway}:${mgmt-netmask}:${config.networking.hostName}:${mgmt-iface}::::"
  ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.network = {
    enable = true;
    postCommands = ''
      echo "cryptsetup-askpass; exit" > /root/.profile
    '';
    ssh = {
      enable = true;
      hostKeys = [ "/etc/ssh/ssh_host_ed25519_key" "/etc/ssh/ssh_host_rsa_key" ];
      authorizedKeys = builtins.filter
        (key: key != "")
        (lib.splitString
          "\n"
          (builtins.readFile (import ../../lib/ssh-keys.nix))
        );
    };
  };

  custom.common.enable = true;
  custom.deploy.enable = true;

  time.timeZone = "America/Los_Angeles";
  networking = {
    hostName = "asparagus";
    domain = "home.arpa";
    nameservers = singleton mgmt-gateway;
    defaultGateway.address = mgmt-gateway;
    interfaces.${mgmt-iface} = {
      useDHCP = false;
      ipv4.addresses = [{
        address = mgmt-address;
        prefixLength = mgmt-prefix;
      }];
    };
    interfaces.wlp0s20f3.useDHCP = false;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
