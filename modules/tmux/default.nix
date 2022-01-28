{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.custom.tmux;
in
{
  options = {
    custom.tmux = {
      enable = mkEnableOption "Custom tmux settings";
    };
  };

  config = mkIf cfg.enable {
    environment.etc."tmux.conf".text = ''
      set  -g default-terminal "screen-256color"
      set  -g base-index      1
      setw -g pane-base-index 1

      set -g status-keys vi
      set -g mode-keys   vi

      setw -g aggressive-resize on
      setw -g clock-mode-style  24
      set  -s escape-time       10
      set  -g history-limit     2000

      unbind C-b
      set -g prefix C-s
      bind C-s send-prefix
      set -g renumber-windows on
      set -g set-clipboard on
      set -g default-command "''${SHELL}"
      set -g status-left-length 50
      set -g status-right "%H:%M %d-%b-%y"
      set-option -g focus-events on
      set-option -sa terminal-overrides ',xterm-256color:RGB'
    '';

    environment.systemPackages = [ pkgs.tmux ];
  };

}
