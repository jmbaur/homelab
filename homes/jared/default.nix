{ config, lib, pkgs, ... }: {
  nixpkgs.config.allowUnfree = true;
  home.packages = with pkgs; [
    age
    awscli2
    bat
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
    gotop
    grex
    gron
    home-manager
    htmlq
    jq
    keybase
    librespeed-cli
    mob
    mosh
    nix-prefetch-docker
    nix-prefetch-git
    nix-tree
    nixos-generators
    nnn
    nvme-cli
    openssl
    p
    patchelf
    picocom
    pinentry
    pstree
    pwgen
    ripgrep
    rtorrent
    sd
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
    unzip
    usbutils
    ventoy-bin
    vim
    xdg-user-dirs
    xdg-utils
    xsv
    ydiff
    yq
    yubikey-manager
    yubikey-personalization
    zf
    zip
    zoxide
  ];

  home.sessionVariables.NNN_TRASH = "1";
  home.sessionVariables.BAT_THEME = "gruvbox-dark";

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
      source = import ../../data/pgp-keys.nix;
      trust = 5;
    }];
  };

  services.gpg-agent = {
    enable = true;
    pinentryFlavor = "tty";
    extraConfig = ''
      allow-loopback-pinentry
    '';
  };

  programs.bash = {
    enable = true;
    enableVteIntegration = true;
    historyControl = [ "ignoredups" ];
    shellAliases = { grep = "grep --color=auto"; };
    historyIgnore = [ "ls" "cd" "exit" ];
  };
  programs.zsh.enable = true;
  programs.nushell.enable = true;
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

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
      signByDefault = false;
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
    shell = "\${SHELL}";
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

  programs.bat = {
    enable = true;
  };

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
        # TODO(jared): Move the settings directory
        settings = pkgs.vimUtils.buildVimPlugin { name = "settings"; src = builtins.path { path = ../../modules/neovim/settings; }; };
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
        gruvbox-nvim
        lsp-colors-nvim
        lualine-nvim
        lush-nvim
        nvim-autopairs
        nvim-lspconfig
        nvim-treesitter-context
        nvim-treesitter-textobjects
        settings
        snippets-nvim
        telescope-nvim
        telescope-zf-native
        toggleterm-nvim
        trouble-nvim
        typescript-vim
        vim-better-whitespace
        vim-cue
        vim-dadbod
        vim-easy-align
        vim-eunuch
        vim-fugitive
        vim-lastplace
        vim-nix
        vim-repeat
        vim-rsi
        vim-surround
        vim-terraform
        vim-vinegar
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

  programs.kitty = {
    enable = true;
    font.name = "Hack";
    font.size = 14;
    settings = {
      copy_on_select = "yes";
      enable_audio_bell = "no";
      mouse_hide_wait = 0;
      term = "xterm-256color";
      update_check_interval = 0;
    };
    extraConfig = ''
      include ${pkgs.kitty-themes}/themes/gruvbox-dark.conf
    '';
  };

}
