{ config, lib, pkgs, ... }: {
  nixpkgs.config.allowUnfree = true;

  home.keyboard.options = [ "ctrl:nocaps" ];

  home.packages = with pkgs; [
    age
    awscli2
    bat
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
    gotop
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
    nmap
    nnn
    nvme-cli
    openssl
    p
    patchelf
    picocom
    pinentry-gnome
    podman-compose
    pstree
    pulsemixer
    pwgen
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
    unzip
    usbutils
    ventoy-bin
    xdg-utils
    xsv
    ydiff
    yq
    yubikey-manager
    yubikey-personalization
    zf
    zip
    zoxide
  ] ++ (with pkgs; [
    bitwarden
    chromium
    element-desktop
    firefox
    signal-desktop
    slack
    spotify
    virt-manager
    zoom-us
  ]);

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
    pinentryFlavor = "gnome3";
    defaultCacheTtl = 3600;
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

  home.sessionVariables.BAT_THEME = "gruvbox-dark";
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

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  gtk = rec {
    enable = true;
    gtk3.extraConfig = {
      gtk-key-theme-name = "Emacs";
      gtk-application-prefer-dark-theme = true;
    };
    gtk4 = gtk3;
  };

  programs.kitty = {
    enable = true;
    font.name = "Hack";
    font.package = pkgs.hack-font;
    font.size = 14;
    settings = {
      copy_on_select = "yes";
      enable_audio_bell = "no";
      mouse_hide_wait = 0;
      term = "xterm-256color";
      update_check_interval = 0;
    };
    extraConfig =
      let
        gruvbox-theme = pkgs.fetchFromGitHub {
          owner = "wdomitrz";
          repo = "kitty-gruvbox-theme";
          rev = "81af12d1cc811cde2e1bf3ec89da9cde8e654b9f";
          sha256 = "158bvv147ksyk04jmmxx0fmsy65fi6pilbp67xlyknasn9cjahlf";
        };
      in
      ''
        include ${gruvbox-theme}/gruvbox_dark.conf
      '';
  };

  xresources = {
    properties = {
      "XTerm.vt100.faceName" = "Hack:size=14:antialias=true";
    };
    extraConfig = builtins.readFile (pkgs.fetchFromGitHub
      {
        repo = "gruvbox-contrib";
        owner = "morhetz";
        rev = "150e9ca30fcd679400dc388c24930e5ec8c98a9f";
        sha256 = "181irx5jas3iqqdlc6v34673p2s6bsr8l0nqbs8gsv88r8q066l6";
      } + "/xresources/gruvbox-dark.xresources");
  };

  programs.i3status = {
    enable = true;
    enableDefault = true;
  };

  programs.autorandr =
    let
      DP2-3 = "00ffffffffffff0030aef561524734502f1e0104a5351e783ee235a75449a2250c5054bdef0081809500b300d1c0d100714f818f0101565e00a0a0a02950302035000f282100001a000000ff0056333036503447520a20202020000000fd00304c1e721e010a202020202020000000fc004c454e20503234712d32300a20015302031cf1490102030413901f1211230907078301000065030c001000011d007251d01e206e2855000f282100001ecc7400a0a0a01e50302035000f282100001a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009f";
      eDP1 = "00ffffffffffff0030e446040000000000170104951f1178ea4575a05b5592270c5054000000010101010101010101010101010101012e3680a070381f403020350035ae1000001a000000000000000000000000000000000000000000fe004c4720446973706c61790a2020000000fe004c503134305746332d53504c3100a8";
    in
    {
      enable = true;
      profiles.docked = {
        fingerprint = { inherit DP2-3 eDP1; };
        config.eDP1.enable = false;
        config.DP2-3 = {
          enable = true;
          primary = true;
          mode = "2560x1440";
          rate = "74.78";
        };
      };
      profiles.laptop = {
        fingerprint = { inherit eDP1; };
        config.eDP1.enable = true;
      };
    };

  programs.rofi = {
    enable = true;
    plugins = [ pkgs.rofi-emoji ];
    extraConfig.modi = "drun,emoji,ssh";
    font = "Hack 12";
    theme = "gruvbox-dark-soft";
    terminal = "${pkgs.kitty}/bin/kitty";
  };

  xsession = {
    enable = true;
    pointerCursor.package = pkgs.gnome.gnome-themes-extra;
    pointerCursor.name = "Adwaita";
    initExtra = ''
      ${pkgs.xorg.xsetroot}/bin/xsetroot -solid "#282828"
      ${pkgs.autorandr}/bin/autorandr --change
    '';
    windowManager.i3 = {
      enable = true;
      config = {
        terminal = "kitty";
        modifier = "Mod4";
        defaultWorkspace = "workspace number 1";
        fonts = { names = [ "Hack" ]; size = 10.0; };
        keybindings =
          let
            mod = config.xsession.windowManager.i3.config.modifier;
          in
          lib.mkOptionDefault {
            "${mod}+Shift+h" = "move left";
            "${mod}+Shift+j" = "move down";
            "${mod}+Shift+k" = "move up";
            "${mod}+Shift+l" = "move right";
            "${mod}+Shift+s" = "sticky toggle";
            "${mod}+Tab" = "workspace back_and_forth";
            "${mod}+c" = "exec clipmenu";
            "${mod}+h" = "focus left";
            "${mod}+j" = "focus down";
            "${mod}+k" = "focus up";
            "${mod}+l" = "focus right";
            "${mod}+p" = "exec rofi -show drun";
            "XF86AudioLowerVolume" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5%";
            "XF86AudioMicMute" = "exec ${pkgs.pulseaudio}/bin/pactl set-source-mute @DEFAULT_SOURCE@ toggle";
            "XF86AudioMute" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle";
            "XF86AudioRaiseVolume" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5%";
            "XF86MonBrightnessDown" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 5%-";
            "XF86MonBrightnessUp" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set +5%";
          };
        bars = [{
          fonts = config.xsession.windowManager.i3.config.fonts;
          statusCommand = "${pkgs.i3status}/bin/i3status";
          trayOutput = "primary";
          position = "top";
        }];
      };
      extraConfig = ''
        workspace_auto_back_and_forth yes
        for_window [all] title_window_icon on
      '';
    };
  };

  home.sessionVariables.CM_LAUNCHER = "rofi";
  services.clipmenu.enable = true;

  services.poweralertd.enable = true;

  services.xcape.enable = true;

  services.dunst = {
    enable = true;
    iconTheme = {
      package = pkgs.gnome.gnome-themes-extra;
      name = "Adwaita";
    };
    settings = {
      global = {
        geometry = "300x5-30+50";
        font = "Hack 12";
      };
    };
  };

  services.redshift = {
    enable = true;
    provider = "geoclue2";
  };

  services.screen-locker = {
    enable = true;
    lockCmd = "${pkgs.i3lock}/bin/i3lock -n -c 282828";
  };

}
