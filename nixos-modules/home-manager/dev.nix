{ nixosConfig, config, lib, pkgs, ... }:
let
  cfg = config.custom.dev;
in
with lib; {
  options.custom.dev = {
    enable = mkOption {
      type = types.bool;
      default = nixosConfig.custom.dev.enable;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      ansifilter
      as-tree
      bc
      bintools
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
      fd
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
      neovim-all-languages
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
      wip
      xsv
      ydiff
      yj
    ];

    programs.gpg = {
      enable = true;
      mutableKeys = false;
      mutableTrust = false;
      scdaemonSettings.disable-ccid = true;
    };

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
      delta = {
        enable = false;
        options = {
          syntax-theme = config.programs.bat.config.theme;
          line-numbers = true;
          navigate = true;
          side-by-side = true;
        };
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

    programs.bottom.enable = true;

    programs.tmux = {
      enable = true;
      inherit (nixosConfig.programs.tmux)
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
      extraConfig = nixosConfig.programs.tmux.extraConfig + ''
        bind-key J command-prompt -p "join pane from:"  "join-pane -h -s '%%'"
        bind-key j display-popup -E -h 75% -w 75% -b double -T "Jump to:" "${pkgs.j}/bin/j"
        set-option -g status-left-length 50
      '';
    };

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    programs.zoxide.enable = true;

    home.sessionVariables.PROJECTS_DIR = "${config.home.homeDirectory}/projects";

    xdg.configFile."fd/ignore".text = ''
      .git
    '';

    # commonly-used nix shells
    xdg.configFile.shells = { recursive = true; source = ./shells; };

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
      envFile.text = "";
    };

    programs.bat = {
      enable = true;
      config.theme = "Nord";
    };

    home.file.".sqliterc".text = ''
      .headers ON
      .mode columns
    '';
  };
}
