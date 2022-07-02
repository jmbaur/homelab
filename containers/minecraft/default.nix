{ config, lib, pkgs, ... }: {
  networking = {
    useDHCP = false;
    useHostResolvConf = false;
    hostName = "minecraft";
    domain = "home.arpa";
    defaultGateway = {
      address = "192.168.30.1";
      interface = "eth0";
    };
    defaultGateway6 = {
      address = "fd82:f21d:118d:1e::1";
      interface = "eth0";
    };
    nameservers = with config.networking; [
      defaultGateway.address
      defaultGateway6.address
    ];
  };
  nixpkgs.config.allowUnfree = true;
  services.minecraft-server = {
    enable = true;
    eula = true;
    declarative = true;
    openFirewall = true;
    dataDir = "/var/lib/minecraft";
  };
}
