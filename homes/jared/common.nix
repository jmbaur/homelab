{ config, lib, pkgs, ... }:
let
  cfg = config.custom.common;
in
{
  options.custom.common.enable = lib.mkEnableOption "Enable common configs";
  config = lib.mkIf cfg.enable {
    nixpkgs.config.allowUnfree = true;

    home.keyboard.options = [ "ctrl:nocaps" ];
    home.shellAliases = {
      grep = "grep --color=auto";
    };

    home.packages = with pkgs; [
      age
      awscli2
      bat
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
      jq
      keybase
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
      nnn
      nvme-cli
      openssl
      p
      patchelf
      picocom
      pinentry-gnome
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
      trash-cli
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

    home.sessionVariables.NNN_TRASH = "1";

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
      extraConfig = ''
        allow-loopback-pinentry
      '';
    };

    programs.zsh.enable = true;
    programs.nushell.enable = true;

    programs.git = {
      enable = true;
      aliases = {
        st = "status --short --branch";
        di = "diff";
        br = "branch";
        co = "checkout";
        lg = "log --graph --decorate --pretty=oneline --abbrev-commit --all";
      };
      delta.enable = true;
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
      terminal = "screen-256color";
      shell = "${pkgs.zsh}/bin/zsh";
      plugins = with pkgs.tmuxPlugins; [ fingers logging ];
      extraConfig = ''
        set -g renumber-windows on
        set -g set-clipboard on
        set -g status-left-length 50
        set -g status-right "%H:%M %d-%b-%y"
        set-option -g focus-events on
        set-option -sa terminal-overrides ',xterm-256color:RGB'
      '';
    };

    home.sessionVariables.BAT_THEME = "ansi"; # also configures git-delta
    programs.bat.enable = true;

    programs.direnv = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    home.sessionVariables.SUMNEKO_ROOT_PATH = "${pkgs.sumneko-lua-language-server}";
    home.sessionVariables.EDITOR = "nvim";
    programs.neovim = {
      enable = true;
      vimAlias = true;
      vimdiffAlias = true;
      plugins =
        let
          vim-dim = pkgs.vimUtils.buildVimPlugin {
            name = "vim-dim";
            src = pkgs.fetchFromGitHub {
              owner = "jeffkreeftmeijer";
              repo = "vim-dim";
              rev = "8320a40f12cf89295afc4f13eb10159f29c43777";
              sha256 = "0mnwr4kxhng4mzds8l72s5km1qww4bifn5pds68c7zzyyy17ffxh";
            };
          };
          telescope-zf-native = pkgs.vimUtils.buildVimPlugin {
            name = "telescope-zf-native.nvim";
            src = pkgs.fetchFromGitHub {
              owner = "natecraddock";
              repo = "telescope-zf-native.nvim";
              rev = "76ae732e4af79298cf3582ec98234ada9e466b58";
              sha256 = "sha256-acV3sXcVohjpOd9M2mf7EJ7jqGI+zj0BH9l0DJa14ak=";
            };
          };
        in
        with pkgs.vimPlugins; [
          (nvim-treesitter.withPlugins (plugins: pkgs.tree-sitter.allGrammars))
          comment-nvim
          editorconfig-vim
          jmbaur-settings
          lsp-colors-nvim
          nvim-autopairs
          nvim-lspconfig
          nvim-treesitter-textobjects
          snippets-nvim
          telescope-nvim
          telescope-zf-native
          toggleterm-nvim
          trouble-nvim
          typescript-vim
          vim-better-whitespace
          vim-cue
          vim-dadbod
          vim-dim
          vim-dirvish
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
        clang-tools
        efm-langserver
        git
        go_1_18
        gotools
        gopls
        luaformatter
        nixpkgs-fmt
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

    xdg.userDirs = {
      enable = true;
      createDirectories = true;
    };

  };
}
