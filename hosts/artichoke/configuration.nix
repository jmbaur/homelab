{ config, lib, pkgs, ... }: {
  # imports = [
  #   ./atftpd.nix
  #   ./dhcpv6.nix
  #   ./dns.nix
  #   ./hardware-configuration.nix
  #   ./lan.nix
  #   ./monitoring.nix
  #   ./nftables.nix
  #   ./options.nix
  #   ./wan.nix
  #   ./wireguard.nix
  # ];

  hardware.cn913x.enable = true;

  custom = {
    common.enable = true;
    deployee = {
      enable = true;
      authorizedKeyFiles = [
        (import ../../data/jmbaur-ssh-keys.nix)
        ../../data/deployer-ssh-keys.txt
      ];
    };
  };

  zramSwap.enable = true;

  networking = {
    hostName = "artichoke";
    useDHCP = false;
    useNetworkd = true;
  };

  systemd.network = {
    links = {
      "10-wan" = {
        matchConfig.MACAddress = "1a:30:ef:95:e9:48";
        linkConfig.Name = "wan";
      };
      # 10Gbps link
      "10-data" = {
        matchConfig.MACAddress = "c2:59:d8:63:46:da";
        linkConfig.Name = "data";
      };
    };
    networks = {
      wan = {
        name = config.systemd.network.links."10-wan".linkConfig.Name;
        DHCP = "yes";
      };
    };
  };

  users.users.jared = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keyFiles = [ (import ../../data/jmbaur-ssh-keys.nix) ];
  };

  system.stateVersion = "22.11";
}
