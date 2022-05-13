{ config, lib, pkgs, ... }:
let
  cfg = config.custom.common;
in
{
  options.custom.common.enable = lib.mkEnableOption "Enable common configs";
  config = lib.mkIf cfg.enable {
    nixpkgs.config.allowUnfree = true;

    home.shellAliases = {
      grep = "grep --color=auto";
    };

    home.packages = with pkgs; [
      age
      awscli2
      buildah
      direnv
      exa
      fd
      fzf
      geteltorito
      gh
      git-get
      gmni
      gosee
      grex
      gron
      htmlq
      htop
      iperf3
      j
      jq
      lf
      librespeed-cli
      mob
      mosh
      neovim
      nix-prefetch-docker
      nix-prefetch-git
      nix-tree
      nixos-generators
      nload
      nmap
      nvme-cli
      openssl
      patchelf
      picocom
      podman-compose
      procs
      pstree
      pwgen
      qemu
      ripgrep
      rtorrent
      sd
      skopeo
      sl
      smartmontools
      speedtest-cli
      sshfs
      ssm-session-manager-plugin
      stow
      tailscale
      tcpdump
      tea
      tealdeer
      tig
      tokei
      tree
      unzip
      usbutils
      w3m
      wireguard-tools
      xsv
      ydiff
      zf
      zip
      zoxide
    ];

    programs.ssh = {
      enable = true;
      controlMaster = "auto";
      matchBlocks."i-* mi-*" = {
        proxyCommand = "${pkgs.bash}/bin/sh -c \"${pkgs.awscli}/bin/aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'\"";
      };
    };

    programs.gpg = {
      enable = true;
      publicKeys = [{
        source = import ../../data/jmbaur-pgp-keys.nix;
        trust = 5;
      }];
    };

    systemd.user.tmpfiles.rules = [
      "d ${config.programs.gpg.homedir} 700 - - -"
    ];

    services.gpg-agent = {
      enable = true;
      defaultCacheTtl = 3600;
    };

    programs.htop = {
      enable = true;
      settings = {
        color_scheme = 6;
        cpu_count_from_one = 0;
        highlight_base_name = 1;
      };
    };

    programs.bat = { enable = true; config.theme = "ansi"; };
    programs.git = {
      enable = true;
      aliases = {
        st = "status --short --branch";
        di = "diff";
        br = "branch";
        co = "checkout";
        lg = "log --graph --decorate --pretty=oneline --abbrev-commit --all";
      };
      delta = {
        enable = true;
        options.syntax-theme = config.programs.bat.config.theme;
      };
      extraConfig = {
        pull.rebase = true;
        init.defaultBranch = "main";
      };
      attributes = [ ];
      ignores = [ "*~" "*.swp" ];
      signing = {
        key = "7EB08143";
        signByDefault = true;
      };
      userEmail = "jaredbaur@fastmail.com";
      userName = "Jared Baur";
    };

    programs.dircolors.enable = true;

    programs.tmux = {
      enable = true;
      aggressiveResize = true;
      baseIndex = 1;
      clock24 = true;
      disableConfirmationPrompt = true;
      escapeTime = 10;
      keyMode = "vi";
      plugins = with pkgs.tmuxPlugins; [ logging ];
      prefix = "C-s";
      shell = "${pkgs.zsh}/bin/zsh";
      terminal = "tmux-256color";
      extraConfig = ''
        bind-key C-l lock-session
        bind-key j display-popup -E -w 90% "${pkgs.j}/bin/j"
        set-option -g focus-events on
        set-option -g lock-after-time 3600
        set-option -g lock-command ${pkgs.vlock}/bin/vlock
        set-option -g renumber-windows on
        set-option -g set-clipboard on
        set-option -g status-left-length 50
        set-option -g status-right '#(${pkgs.i3status}/bin/i3status -c ${./tmux-i3status.conf})'
        set-option -g status-right-length 75
        set-option -sa terminal-overrides ',xterm-256color:RGB'
      '';
    };

    programs.bash = {
      enable = true;
      historyControl = [ "ignoredups" "ignorespace" ];
      historyIgnore = [ "ls" "cd" "exit" ];
    };

    programs.zsh = {
      enable = true;
      defaultKeymap = "emacs";
      initExtra = ''
        setopt PROMPT_SUBST
        autoload -Uz vcs_info
        zstyle ':vcs_info:*' enable git
        zstyle ':vcs_info:*' actionformats '%F{magenta}%b%f|%F{red}%a%f '
        zstyle ':vcs_info:*' formats '%F{magenta}%b%f '
        precmd () { vcs_info }
        PS1='%F{green}%n@%m%f:%F{blue}%3~%f ''${vcs_info_msg_0_}%# '
        bindkey \^U backward-kill-line
      '';
    };

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    home.sessionVariables.EDITOR = "nvim";
  };
}
