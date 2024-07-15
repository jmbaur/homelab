{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.custom.tmuxServer.enable = lib.mkEnableOption "tmux-server";

  config = lib.mkIf config.custom.tmuxServer.enable {
    programs.tmux = {
      enable = true;
      keyMode = if config.programs.vim.enable then "vi" else "emacs";
    };

    systemd.user.sockets.tmux = {
      description = "Tmux server";
      socketConfig = {
        ListenStream = "%t/tmux-%U/default";
        SocketMode = "0600";
        DirectoryMode = "0700";
      };
      wantedBy = [ "sockets.target" ];
    };

    systemd.user.services.tmux = {
      description = "Tmux server";
      requires = [ config.systemd.user.sockets.tmux.name ];
      after = [ config.systemd.user.sockets.tmux.name ];
      serviceConfig.ExecStart = "${lib.getExe pkgs.tmux} -D";
    };
  };
}
