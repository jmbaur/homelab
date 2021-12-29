{ config, lib, pkgs, ... }: {
  networking = {
    hostName = "minecraft";
    interfaces.mv-eno2.useDHCP = true;
  };

  nixpkgs.config.allowUnfree = true;

  services.minecraft-server = {
    enable = true;
    eula = true;
    declarative = true;
    dataDir = "/var/lib/minecraft";
    openFirewall = true;
    serverProperties = {
      server-port = 25565;
    };
  };
}
