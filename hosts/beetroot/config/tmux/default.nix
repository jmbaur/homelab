{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.custom.tmux;
in
{
  options = {
    custom.tmux = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable custom tmux settings.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      terminal = "screen-256color";
      secureSocket = true;
      keyMode = "vi";
      clock24 = true;
      baseIndex = 1;
      aggressiveResize = true;
      escapeTime = 10;
      extraConfig = ''
        unbind C-b
        set -g prefix C-s
        bind C-s send-prefix
        set -g set-clipboard on
        set -g renumber-windows on
      '';
    };
  };

}
