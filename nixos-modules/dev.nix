{ config, lib, pkgs, ... }:
let
  cfg = config.custom.dev;
in
with lib;
{
  options.custom.dev.enable = mkEnableOption "dev setup";

  config = mkIf cfg.enable {
    programs = {
      flashrom.enable = true;
      mosh.enable = true;
      wireshark.enable = true;
    };

    # enable some nicer interactive shells
    programs.fish.enable = true;
    programs.zsh.enable = true;

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
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };

    # create a subvolume (or directory if the underlying filesystem doesn't
    # support subvolumes) for dev projects
    systemd.tmpfiles.rules = lib.mapAttrsToList
      (_: user: "v ${user.home}/projects - ${user.name} ${user.group} -")
      (lib.filterAttrs
        (_: user: user.isNormalUser)
        config.users.users);
  };
}
