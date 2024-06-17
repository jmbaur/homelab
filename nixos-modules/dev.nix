{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.dev;
in
{
  options.custom.dev.enable = lib.mkEnableOption "dev setup";

  config = lib.mkIf cfg.enable {
    # presumably we'd be doing nix builds on a dev machine, so we need a mutable nix store
    custom.image.mutableNixStore = lib.mkDefault true;
    environment.systemPackages = lib.optionals config.custom.image.mutableNixStore [
      pkgs.home-manager
    ];

    users.defaultUserShell = pkgs.nushell;

    programs.ssh.startAgent = lib.mkDefault true;
    programs.gnupg.agent.enable = lib.mkDefault true;
    services.pcscd.enable = config.custom.desktop.enable;

    # dev tooling often wants to watch lots of files
    boot.kernel.sysctl = {
      "fs.inotify.max_user_watches" = 100000;
      "fs.inotify.max_queued_events" = 100000;
    };
  };
}
