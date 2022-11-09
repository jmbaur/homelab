{
  enable = true;
  aggressiveResize = true;
  baseIndex = 1;
  clock24 = true;
  escapeTime = 10;
  keyMode = "vi";
  terminal = "tmux-256color";
  extraConfig = ''
    bind-key J command-prompt -p "join pane from:"  "join-pane -h -s '%%'"
    set-option -g allow-passthrough on
    set-option -g automatic-rename on
    set-option -g focus-events on
    set-option -g renumber-windows on
    set-option -g set-clipboard on
    set-option -g set-titles on
    set-option -g set-titles-string "#T"
    set-option -sa terminal-overrides ',xterm-256color:RGB'
  '';
}
