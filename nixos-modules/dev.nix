{ config, lib, ... }:
let
  cfg = config.custom.dev;
in
{
  options.custom.dev.enable = lib.mkEnableOption "dev setup";

  config = lib.mkIf cfg.enable {
    # enable some nicer interactive shells
    programs.fish.enable = true;
    programs.zsh.enable = true;

    programs.ssh.startAgent = true;

    virtualisation.containers = {
      enable = !config.boot.isContainer;
      containersConf.settings.engine.detach_keys = "ctrl-q,ctrl-e";
    };

    virtualisation.podman = {
      enable = !config.boot.isContainer;
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
