{ config, lib, pkgs, ... }: {
  boot.isContainer = true;
  networking = {
    useDHCP = false;
    useHostResolvConf = false;
    hostName = "media";
    domain = "home.arpa";
    defaultGateway = {
      address = "192.168.20.1";
      interface = "eth0";
    };
    defaultGateway6 = {
      address = "fd82:f21d:118d:14::1";
      interface = "eth0";
    };
    nameservers = with config.networking; [
      defaultGateway.address
      defaultGateway6.address
    ];
  };
  systemd.tmpfiles.rules = [
    "d ${config.services.plex.dataDir} 700 ${config.services.plex.user} ${config.services.plex.group} -"
    "d /media 770 ${config.services.plex.user} ${config.services.plex.group} -"
  ];
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age = {
      generateKey = true;
      keyFile = "/var/lib/sops-nix/key.txt";
    };
    secrets."sabnzbd.ini" = {
      owner = config.services.sabnzbd.user;
      group = config.services.sabnzbd.group;
    };
  };
  nixpkgs.config.allowUnfree = true;
  services.plex = {
    enable = true;
    openFirewall = true;
  };
  services.sabnzbd = {
    enable = true;
    # configFile = "/run/secrets/sabnzbd.ini";
  };
  systemd.services.sabnzbd = {
    serviceConfig.SupplementaryGroups = [ config.users.groups.keys.name ];
  };
}
