{ config, lib, pkgs, modulesPath, ... }: {
  imports = [ "${modulesPath}/installer/sd-card/sd-image-aarch64.nix" ];

  custom = {
    server.enable = true;
    disableZfs = true;
    deployee = {
      enable = true;
      authorizedKeyFiles = [ pkgs.jmbaur-github-ssh-keys ];
    };
    wg-mesh = {
      enable = true;
      peers.artichoke.extraOptions = {
        Endpoint = "artichoke.home.arpa:51820"; # "vpn.jmbaur.com:51820";
        PersistentKeepalive = 25;
      };
    };
  };

  zramSwap.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_6_1;
  boot.initrd.systemd.enable = true;

  networking = {
    hostName = "rhubarb";
    useDHCP = false;
  };
  services.resolved = {
    enable = true;
    # The RPI does not have an RTC, so DNSSEC without an accurate time does not
    # work, which means NTP servers cannot be queried.
    dnssec = "false";
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets.wg0 = { mode = "0640"; group = config.users.groups.systemd-network.name; };
  };

  systemd.network = {
    enable = true;
    networks.wired = {
      name = "en*";
      DHCP = "yes";
      dhcpV4Config.ClientIdentifier = "mac";
    };
  };

  environment.systemPackages = [ pkgs.wireguard-tools ];

  system.stateVersion = "23.05";
}
