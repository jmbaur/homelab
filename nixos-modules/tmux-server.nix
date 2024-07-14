{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.custom.tmuxServer.enable = lib.mkEnableOption "tmux-server";

  config = lib.mkIf config.custom.tmuxServer.enable {
    systemd.user.sockets.tmux = {
      description = "Tmux server";
      socketConfig = {
        ListenStream = "%t/tmux-%U/default";
        SocketMode = "0600";
      };
      wantedBy = [ "sockets.target" ];
    };

    systemd.user.services.tmux = {
      description = "Tmux server";
      requires = [ config.systemd.user.sockets.tmux.name ];
      after = [ config.systemd.user.sockets.tmux.name ];

      serviceConfig = {
        Type = "forking";
        ExecStart = "${lib.getExe pkgs.tmux} start-server\; new-session -d";
      };
    };
  };
}
