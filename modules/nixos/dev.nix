{ config, lib, ... }:
let
  cfg = config.custom.dev;
in
with lib;
{
  imports = [ ../shared/dev-options.nix ];
  config = mkIf cfg.enable {
    documentation = {
      enable = true;
      dev.enable = true;
      doc.enable = true;
      info.enable = true;
      man.enable = true;
    };

    programs.mosh.enable = true;

    environment.variables = {
      EDITOR = lib.mkForce "nvim";
      VISUAL = lib.mkForce "nvim";
    };
    environment.pathsToLink = [ "/share/zsh" ];

    nix.extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '';

    programs.ssh.startAgent = true;

    virtualisation.containers = {
      enable = !config.boot.isContainer;
      containersConf.settings.engine.detach_keys = "ctrl-q,ctrl-e";
    };
    virtualisation.podman = {
      enable = !config.boot.isContainer;
      defaultNetwork.dnsname.enable = true;
    };
  };
}
