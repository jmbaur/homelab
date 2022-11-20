{ config, lib, pkgs, systemConfig, ... }:
let cfg = config.custom.dev; in
with lib; {
  options.custom.dev = {
    enable = mkOption {
      type = types.bool;
      default = systemConfig.custom.dev.enable;
    };
  };
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      as-tree
      bintools
      buildah
      cachix
      cntr
      deadnix
      diffsitter
      direnv
      entr
      git
      git-extras
      git-get
      git-gone
      gitui
      gosee
      grex
      gron
      htmlq
      j
      jo
      jq
      just
      macgen
      mdcat
      mob
      mosh
      neovim
      neovim-boring
      nix-prefetch-scripts
      nix-tree
      nixos-generators
      nload
      openssl
      patchelf
      pd-notify
      podman-compose
      procs
      pstree
      qemu
      rage
      ripgrep
      rlwrap
      sd
      skopeo
      tea
      tealdeer
      tokei
      wip
      xsv
      yamlfmt
      ydiff
      yj
      zf
    ] ++ lib.flatten (with systemConfig.custom.dev; [
      (with pkgs; [
        # editor tools
        bat
        deno
        fd
        skim
        html-tidy
        shellcheck
        shfmt
        taplo
        tree-sitter
      ])
      (lib.optionals (languages.all || languages.zig) [
        pkgs.zls
      ])
      (lib.optionals (languages.all || languages.python) [
        pkgs.black
        pkgs.pyright
      ])
      (lib.optionals (languages.all || languages.nix) [
        pkgs.nil
        pkgs.nixpkgs-fmt
      ])
      (lib.optionals (languages.all || languages.lua) [
        pkgs.sumneko-lua-language-server
      ])
      (lib.optionals (languages.all || languages.rust) [
        pkgs.clippy
        pkgs.rust-analyzer
        pkgs.rustfmt
      ])
      (lib.optionals (languages.all || languages.go) [
        pkgs.go-tools
        pkgs.gofumpt
        pkgs.gopls
      ])
      (lib.optionals (languages.all || languages.typescript) [
        pkgs.deno
        pkgs.nodePackages.typescript-language-server
      ])
    ]);

    programs.git = {
      enable = true;
      aliases = {
        br = "branch";
        co = "checkout";
        di = "diff";
        dt = "difftool";
        lg = "log --graph --decorate --pretty=oneline --abbrev-commit --all";
        st = "status --short --branch";
      };
      extraConfig = {
        "difftool \"difftastic\"".cmd = "${pkgs.difftastic}/bin/difft \"$LOCAL\" \"$REMOTE\"";
        blame.ignoreRevsFile = ".git-blame-ignore-revs";
        blame.markIgnoredLines = true;
        blame.markUnblamableLines = true;
        diff.tool = "difftastic";
        difftool.prompt = false;
        init.defaultBranch = "main";
        pager.difftool = true;
        pull.rebase = true;
        push.autoSetupRemote = true;
      };
      attributes = [ ];
      ignores = [ "*~" "*.swp" ];
    };

    programs.gh = {
      enable = true;
      enableGitCredentialHelper = true;
    };

    programs.tmux = {
      enable = true;
      inherit (systemConfig.programs.tmux)
        aggressiveResize
        baseIndex
        clock24
        escapeTime
        keyMode
        plugins
        terminal
        ;
      disableConfirmationPrompt = true;
      prefix = "C-s";
      extraConfig = systemConfig.programs.tmux.extraConfig + ''
        bind-key J command-prompt -p "join pane from:"  "join-pane -h -s '%%'"
        bind-key j display-popup -E -w 90% "${pkgs.j}/bin/j"
        set-option -g status-left-length 75
      '';
    };

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    home.sessionVariables = lib.mkIf (!config.custom.gui.enable) {
      XDG_PROJECTS_DIR = "\${HOME}/projects";
    };

    xdg.configFile."fd/ignore".text = ''
      .git
    '';

    programs.ssh = {
      enable = true;
      controlMaster = "auto";
      controlPersist = "30m";
    };

    programs.bash = {
      enable = true;
      initExtra = ''
        PS1="[\u@\h:\w]$ "
      '';
    };

    programs.zsh = {
      enable = true;
      defaultKeymap = "emacs";
      initExtraFirst = ''
        setopt interactivecomments
        setopt prompt_subst
      '';
      initExtra = ''
        if [[ -n "$SSH_CONNECTION" ]]; then
          psvar=("ssh")
        else
          psvar=()
        fi
        autoload -Uz vcs_info
        set_window_title() { print -Pn "\e]0;[%m] %~\a" }
        precmd_functions+=(vcs_info set_window_title)
        zstyle ':vcs_info:*' actionformats '%F{magenta}(%b|%a)%f'
        zstyle ':vcs_info:git:*' formats '%F{blue}(%b)%f'
        zstyle ':vcs_info:*' enable git
        PROMPT='%F{%(0V.yellow.green)}[%m]%f%F{white}%2~%f$vcs_info_msg_0_%(?..%F{red}[%?]%f)%(!.#.%#) '

        bindkey \^U backward-kill-line
      '';
    };

    programs.nushell = {
      enable = true;
      configFile.source = ./config.nu;
      envFile.source = ./env.nu;
    };

    programs.bat = {
      enable = true;
      config.theme = "ansi";
    };

    home.file.".sqliterc".text = ''
      .headers ON
      .mode columns
    '';
  };
}
