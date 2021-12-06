self: super: {
  tmux =
    let
      tmuxConf = super.writeText "tmux-conf" ''
        set  -g default-terminal screen-256color
        set  -g base-index      1
        setw -g pane-base-index 1

        bind v split-window -h
        bind s split-window -v

        set -g status-keys vi
        set -g mode-keys   vi


        # rebind main key: C-s
        unbind C-b
        set -g prefix C-s
        bind s send-prefix
        bind C-s last-window

        setw -g aggressive-resize 1
        setw -g clock-mode-style  24
        set  -s escape-time       10
        set  -g history-limit     2000

        set -g mouse on
        set -g renumber-windows on
        set -g set-clipboard on
        set -g default-command "''${SHELL}"
        set-option -g focus-events on
        set-option -sa terminal-overrides ',xterm-256color:RGB'
      '';
    in
    super.symlinkJoin {
      inherit (super.tmux) name;
      paths = [ super.tmux ];
      buildInputs = [ super.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/tmux \
          --add-flags "-f ${tmuxConf}"
      '';
    };
}
