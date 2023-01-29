{ config, lib, pkgs, systemConfig, ... }:
let
  cfg = config.custom.dev;
  colors = import ./colors.nix;
in
with lib; {
  options.custom.dev = {
    enable = mkOption {
      type = types.bool;
      default = systemConfig.custom.dev.enable;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      ansifilter
      as-tree
      bc
      bintools
      bottom
      buildah
      cachix
      cntr
      curl
      deadnix
      diffsitter
      dig
      direnv
      dnsutils
      entr
      file
      fsrx
      git
      git-extras
      git-get
      git-gone
      gnumake
      gosee
      grex
      gron
      htmlq
      htop-vim
      iputils
      ixio
      j
      jo
      jq
      just
      killall
      lm_sensors
      lsof
      macgen
      mdcat
      mob
      mosh
      neovim
      neovim-boring
      nix-diff
      nix-prefetch-scripts
      nix-tree
      nixos-generators
      nload
      nurl
      openssl
      patchelf
      pciutils
      pd-notify
      podman-compose
      podman-tui
      pomo
      procs
      pstree
      qemu
      rage
      ripgrep
      rlwrap
      sd
      skopeo
      tcpdump
      tea
      tealdeer
      tig
      tokei
      traceroute
      usbutils
      wezterm
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
      (lib.optionals (languages.all || languages.c) [
        pkgs.clang-tools
      ])
      (lib.optionals (languages.all || languages.zig) [
        pkgs.zls
      ])
      (lib.optionals (languages.all || languages.python) [
        pkgs.ruff
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

    programs.gpg = {
      enable = true;
      mutableKeys = false;
      mutableTrust = false;
      scdaemonSettings.disable-ccid = true;
    };
    services.gpg-agent.enable = true;

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
        bind-key j display-popup -E -h 75% -w 75% -b double -T "Jump to:" "${pkgs.j}/bin/j"
        set-option -g status-left-length 75
      '';
    };

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    programs.zoxide.enable = true;

    home.sessionVariables = lib.mkIf (!config.custom.gui.enable) {
      XDG_PROJECTS_DIR = "\${HOME}/projects";
    };

    xdg.configFile."fd/ignore".text = ''
      .git
    '';

    # commonly-used nix shells
    xdg.configFile.shells = { recursive = true; source = ./shells; };

    xdg.configFile."wezterm/wezterm.lua".source = ./wezterm.lua;
    xdg.configFile."wezterm/colors/modus-operandi.toml".source = (pkgs.formats.toml { }).generate "modus-operandi.toml" {
      colors = {
        background = "#${colors.background}";
        foreground = "#${colors.foreground}";
        selection_bg = "rgba(40% 40% 40% 40%)";
        selection_fg = "none";
        ansi = map (color: "#${color}") [ colors.regular0 colors.regular1 colors.regular2 colors.regular3 colors.regular4 colors.regular5 colors.regular6 colors.regular7 ];
        brights = map (color: "#${color}") [ colors.bright0 colors.bright1 colors.bright2 colors.bright3 colors.bright4 colors.bright5 colors.bright6 colors.bright7 ];
      };
      metadata.name = "modus-operandi";
    };

    programs.ssh = {
      enable = true;
      controlMaster = "auto";
      controlPersist = "30m";
      # ensure that local terminal terminfo's don't have to exist on any remote machine
      extraOptionOverrides.SetEnv = "TERM=xterm-256color";
    };

    programs.fish = {
      enable = true;
      loginShellInit = ''
        set -U fish_greeting ""
      '';
    };

    programs.zsh = {
      enable = true;
      defaultKeymap = "emacs";
      initExtraFirst = ''
        setopt interactivecomments
        setopt nonomatch
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
        zstyle ':vcs_info:git:*' formats '%F{cyan}(%b)%f'
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
