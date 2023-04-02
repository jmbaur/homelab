{ config, pkgs, modulesPath, ... }: {
  imports = [ "${modulesPath}/installer/sd-card/sd-image-aarch64.nix" ];
  nixpkgs.hostPlatform = "aarch64-linux";

  custom = {
    crossCompile.enable = true;
    server.enable = true;
    disableZfs = true;
    deployee = {
      enable = true;
      authorizedKeyFiles = [ pkgs.jmbaur-github-ssh-keys ];
    };
    wg-mesh = {
      enable = true;
      peers.artichoke.extraConfig = {
        Endpoint = "vpn.jmbaur.com:51820";
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
    firewall.allowedTCPPorts = [ 22 ];
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

  system.stateVersion = "23.05";
}
