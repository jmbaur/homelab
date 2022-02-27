{ config, lib, pkgs, ... }: {
  boot.isContainer = true;
  networking = {
    useDHCP = false;
    useHostResolvConf = false;
    hostName = "media";
    defaultGateway.address = "192.168.20.1";
    defaultGateway.interface = "mv-publan";
    nameservers = lib.singleton "192.168.20.1";
    domain = "home.arpa";
    interfaces.mv-publan.ipv4.addresses = [{
      address = "192.168.20.29";
      prefixLength = 24;
    }];
    interfaces.mv-publan.ipv6.addresses = [{
      address = "2001:470:f001:20::29";
      prefixLength = 64;
    }];
  };
  systemd.tmpfiles.rules = [
    "d ${config.services.plex.dataDir} 700 ${config.services.plex.user} ${config.services.plex.group} -"
    "d ${config.services.sonarr.dataDir} 700 ${config.services.sonarr.user} ${config.services.sonarr.group} -"
    "d ${config.services.lidarr.dataDir} 700 ${config.services.lidarr.user} ${config.services.lidarr.group} -"
    "d ${config.services.radarr.dataDir} 700 ${config.services.radarr.user} ${config.services.radarr.group} -"
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
  services.lidarr = {
    enable = true;
    openFirewall = true;
  };
  services.radarr = {
    enable = true;
    openFirewall = true;
  };
  services.sonarr = {
    enable = true;
    openFirewall = true;
  };
  users.users.plex.extraGroups = [
    config.services.lidarr.group
    config.services.radarr.group
    config.services.sonarr.group
  ];
  users.users.lidarr.extraGroups = [ config.services.sabnzbd.group ];
  users.users.radarr.extraGroups = [ config.services.sabnzbd.group ];
  users.users.sonarr.extraGroups = [ config.services.sabnzbd.group ];
}
