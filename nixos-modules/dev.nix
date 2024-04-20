{ config, lib, ... }:
let
  cfg = config.custom.dev;
in
{
  options.custom.dev.enable = lib.mkEnableOption "dev setup";

  config = lib.mkIf cfg.enable {
    # dev tooling often wants to watch lots of files
    boot.kernel.sysctl = {
      "fs.inotify.max_user_watches" = 100000;
      "fs.inotify.max_queued_events" = 100000;
    };

    # enable some nicer interactive shells
    programs.fish.enable = true;
    programs.zsh.enable = true;

    programs.ssh.startAgent = true;
  };
}
