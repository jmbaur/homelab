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
      bat
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

    home.sessionVariables.PROJECTS_DIR = "${config.home.homeDirectory}/projects";

    programs.ssh = {
      enable = true;
      controlMaster = "auto";
      controlPersist = "30m";
      # ensure that local terminal terminfo's don't have to exist on any remote machine
      extraOptionOverrides.SetEnv = "TERM=xterm-256color";
    };
  };
}
