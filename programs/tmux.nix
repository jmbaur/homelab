{ config, pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    aggressiveResize = true;
    baseIndex = 1;
    clock24 = true;
    disableConfirmationPrompt = true;
    escapeTime = 10;
    keyMode = "vi";
    prefix = "C-s";
    sensibleOnTop = false;
    terminal = "screen-256color";
    plugins = with pkgs.tmuxPlugins; [ logging resurrect yank ];
    extraConfig = ''
      set -g set-clipboard on
      set -g renumber-windows on
      set-option -g focus-events on
      set-option -ga terminal-overrides ',xterm-256color:Tc'
    '';
  };

}
