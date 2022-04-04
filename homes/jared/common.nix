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
      ddcutil
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
      jq
      keybase
      lf
      libnotify
      librespeed-cli
      mob
      mosh
      nix-prefetch-docker
      nix-prefetch-git
      nix-tree
      nixos-generators
      nload
      nmap
      nvme-cli
      openssl
      p
      patchelf
      picocom
      podman-compose
      procs
      pstree
      pulsemixer
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
      ventoy-bin
      wireguard-tools
      xdg-utils
      xsv
      ydiff
      yq
      yubikey-manager
      yubikey-personalization
      zellij
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

    programs.bat = { enable = true; config.theme = "gruvbox-dark"; };
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
        set -g renumber-windows on
        set -g set-clipboard on
        set -g status-left-length 50
        set -g status-right "%H:%M %d-%b-%y"
        set -g focus-events on
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

    home.sessionVariables.SUMNEKO_ROOT_PATH = pkgs.sumneko-lua-language-server;
    home.sessionVariables.EDITOR = "nvim";
    programs.neovim = {
      enable = true;
      vimAlias = true;
      vimdiffAlias = true;
      plugins = with pkgs.vimPlugins; [
        (nvim-treesitter.withPlugins (plugins: pkgs.tree-sitter.allGrammars))
        comment-nvim
        editorconfig-vim
        formatter-nvim
        gruvbox-nvim
        jmbaur-settings
        nvim-autopairs
        nvim-lspconfig
        nvim-treesitter-textobjects
        snippets-nvim
        telescope-nvim
        telescope-zf-native
        typescript-vim
        vim-better-whitespace
        vim-cue
        vim-dadbod
        vim-dirvish
        vim-dispatch
        vim-easy-align
        vim-eunuch
        vim-fugitive
        vim-lastplace
        vim-nix
        vim-repeat
        vim-rsi
        vim-surround
        vim-terraform
        zig-vim
      ];
      extraPackages = with pkgs; [
        bat
        black
        cargo
        efm-langserver
        git
        go_1_18
        gopls
        gotools
        luaformatter
        nixpkgs-fmt
        nodePackages.prettier
        nodePackages.typescript
        nodePackages.typescript-language-server
        nodejs
        pyright
        python3
        ripgrep
        rust-analyzer
        rustfmt
        shfmt
        sumneko-lua-language-server
        texlive.combined.scheme-medium
        tree-sitter
        zig
        zls
      ];
    };

  };
}
