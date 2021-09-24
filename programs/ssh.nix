{ config, pkgs, ... }:
{
  home-manager.users.jared.programs.ssh = {
    enable = true;
    controlMaster = "auto";
    controlPath = "/tmp/ssh_%r@%h:%p";
    forwardAgent = true;
    matchBlocks = {
      "kale" = {
        user = "root";
        hostname = "kale.lan";
      };
    };
    extraConfig = ''
      Include ~/.ssh/config_prenda
      Include ~/.ssh/config_artsreach
    '';
  };
}
