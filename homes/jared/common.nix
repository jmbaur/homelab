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
      # yq # currently broken
      age
      awscli2
      buildah
      direnv
      dust
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

    programs.bat = { enable = true; config.theme = "Solarized (dark)"; };
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

    programs.tmux = {
      enable = true;
      aggressiveResize = true;
      baseIndex = 1;
      clock24 = true;
      disableConfirmationPrompt = true;
      escapeTime = 10;
      keyMode = "vi";
      prefix = "C-s";
      terminal = "tmux-256color";
      plugins = with pkgs.tmuxPlugins; [ logging ];
      extraConfig = ''
        bind-key "j" display-popup -E -w 90% "${pkgs.j}/bin/j"
        set -g focus-events on
        set -g renumber-windows on
        set -g set-clipboard on
        set -g status-left-length 50
        set -g status-right "%H:%M %d-%b-%y"
        set -sa terminal-overrides ',xterm-256color:RGB'
      '';
    };

    programs.bash = {
      enable = true;
      historyControl = [ "ignoredups" "ignorespace" ];
      historyIgnore = [ "ls" "cd" "exit" ];
    };

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # TODO(jared): figure out how to do this within github:jmbaur/neovim flake
    home.sessionVariables.SUMNEKO_ROOT_PATH = pkgs.sumneko-lua-language-server;
    home.sessionVariables.EDITOR = "nvim";
  };
}
