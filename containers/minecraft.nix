{ config, lib, pkgs, ... }: {
  services.minecraft-server = {
    enable = true;
    eula = true;
    declarative = true;
    openFirewall = true;
    dataDir = "/var/lib/minecraft";
  };
}
