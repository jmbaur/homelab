{ config, lib, pkgs, ... }:
let
  cfg = config.custom.dev;
in
{
  options.custom.dev.enable = lib.mkEnableOption "dev setup";

  config = lib.mkIf cfg.enable {
    # add some useful tools that need udev rules and/or suid/sgid capabilities
    programs.flashrom.enable = true;
    programs.wireshark.enable = true;

    # enable some nicer interactive shells
    programs.fish.enable = true;
    programs.zsh.enable = true;

    # add some helpful manpages
    environment.systemPackages = [ pkgs.man-pages pkgs.man-pages-posix ];

    documentation.enable = true;
    documentation.doc.enable = true;
    documentation.info.enable = true;
    documentation.man.enable = true;
    documentation.nixos.enable = true;

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
