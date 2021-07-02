{ config, pkgs, ... }: {
  home-manager.users.jared.programs.tmux = {
    enable = true;
    prefix = "C-a";
    aggressiveResize = true;
    clock24 = true;
    disableConfirmationPrompt = true;
    escapeTime = 10;
    keyMode = "vi";
    customPaneNavigationAndResize = true;
    newSession = true;
    terminal = "tmux-256color";
    shell = "${pkgs.zsh}/bin/zsh";
    baseIndex = 1;
    sensibleOnTop = false;
    secureSocket = true;
    plugins = with pkgs.tmuxPlugins; [
      sensible
      logging
      resurrect
      fingers
      yank
      pain-control
    ];
    extraConfig = ''
      set -g renumber-windows on
      set -g update-environment "SSH_AUTH_SOCK SSH_CONNECTION"
      set-option -sa terminal-overrides ',xterm-256color:RGB'
      bind-key b set-option status
      bind-key / command-prompt "split-window 'exec man %%'"
      bind-key S command-prompt "new-window -n %1 'ssh %1'"
    '';
  };
}
