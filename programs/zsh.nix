{ config, pkgs, ... }: {
  home-manager.users.jared.programs.zsh = {
    enable = true;
    enableCompletion = true;
    autocd = true;
    defaultKeymap = "emacs";
    history = { ignoreDups = true; };
    shellAliases = {
      ls = "ls --color=auto";
      ll = "ls -alh";
      grep = "grep --color=auto";
    };
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "systemd" ];
      theme = "risto";
    };
    initExtra = ''
      bindkey \^U backward-kill-line
    '';
  };
}
