{ config, lib, pkgs, ... }:
let
  cfg = config.custom.dev;
  guiEnabled = config.custom.gui.enable;
in
{
  options.custom.dev.enable = lib.mkEnableOption "Enable development configs";

  config = lib.mkIf cfg.enable {
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
      gosee
      grex
      gron
      htmlq
      j
      jq
      lf
      mob
      mosh
      neovim
      nix-prefetch-docker
      nix-prefetch-git
      nix-tree
      nixos-generators
      nload
      openssl
      patchelf
      podman-compose
      procs
      pstree
      qemu
      ripgrep
      sd
      skopeo
      tea
      tealdeer
      tig
      tokei
      xsv
      ydiff
      zf
      zoxide
    ];

    programs.gpg = {
      enable = true;
      mutableKeys = false;
      mutableTrust = false;
      publicKeys = [{
        source = import ../../data/jmbaur-pgp-keys.nix;
        trust = 5;
      }];
    };
    systemd.user.tmpfiles.rules = [
      "d ${config.programs.gpg.homedir} 700 - - -"
    ];

    programs.git = {
      enable = true;
      aliases = {
        st = "status --short --branch";
        di = "diff";
        br = "branch";
        co = "checkout";
        lg = "log --graph --decorate --pretty=oneline --abbrev-commit --all";
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
        set-option -sa terminal-overrides ',xterm-256color:RGB'
      '';
    };

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    home.sessionVariables = {
      EDITOR = "${pkgs.neovim}/bin/nvim";
      PAGER = "${pkgs.nvimpager}/bin/nvimpager";
    };

    programs.zsh = {
      enable = true;
      defaultKeymap = "emacs";
      completionInit = ''
        autoload -Uz compinit bashcompinit && compinit && bashcompinit
        complete -C '${pkgs.awscli}/bin/aws_completer' aws
      '';
      initExtraFirst = ''
        setopt PROMPT_SUBST
      '';
      initExtra = ''
        autoload -Uz vcs_info
        zstyle ':vcs_info:*' enable git
        zstyle ':vcs_info:*' actionformats '%F{magenta}%b%f|%F{red}%a%f '
        zstyle ':vcs_info:*' formats '%F{magenta}%b%f '
        precmd () { vcs_info }
        PS1='%F{green}%n@%m%f:%F{blue}%3~%f ''${vcs_info_msg_0_}%# '

        bindkey \^U backward-kill-line
      '';
    };

    programs.bash = {
      enable = true;
      historyControl = [ "ignoredups" "ignorespace" ];
      historyIgnore = [ "ls" "cd" "exit" ];
    };

    programs.alacritty = lib.mkIf guiEnabled {
      enable = true;
      settings = {
        env.TERM = "xterm-256color";
        mouse.hide_when_typing = true;
        import = [ ];
        font = {
          normal.family = config.programs.kitty.font.name;
          bold.family = config.programs.kitty.font.name;
          italic.family = config.programs.kitty.font.name;
          bold_italic.family = config.programs.kitty.font.name;
          size = config.programs.kitty.font.size;
        };
      };
    };

    programs.foot = lib.mkIf guiEnabled {
      enable = true;
      settings = {
        main = {
          dpi-aware = "yes";
          font = "${config.programs.kitty.font.name}:size=${toString (config.programs.kitty.font.size - 7)}, Noto Color Emoji";
          selection-target = "both";
          term = "xterm-256color";
        };
        mouse.hide-when-typing = "yes";
      };
    };

    programs.vscode = lib.mkIf guiEnabled {
      enable = true;
      mutableExtensionsDir = false;
      extensions = with pkgs.vscode-extensions; [
        asvetliakov.vscode-neovim
        bbenoist.nix
        ms-vsliveshare.vsliveshare
      ];
      userSettings = {
        "breadcrumbs.enabled" = false;
        "editor.fontFamily" = config.programs.kitty.font.name;
        "editor.fontSize" = config.programs.kitty.font.size + 4;
        "editor.minimap.enabled" = false;
        "extensions.ignoreRecommendations" = true;
        "telemetry.telemetryLevel" = "off";
        "terminal.external.linuxExec" = config.wayland.windowManager.sway.config.terminal;
        "vscode-neovim.neovimExecutablePaths.linux" = "${pkgs.neovim-embed}/bin/nvim";
      };
    };
  };
}
