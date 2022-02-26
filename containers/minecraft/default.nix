{ config, lib, pkgs, ... }: {
  networking = {
    useHostResolvConf = false;
    interfaces.mv-publan.useDHCP = true;
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
