{ config, pkgs, system ? builtins.currentSystem, ... }:

let
  audio = import ../programs/audio.nix;
  fdroidcl = import ../programs/fdroidcl.nix;
  gosee = import (builtins.fetchGit { "url" = "https://github.com/jmbaur/gosee.git"; ref = "main"; });
  home-manager = import ../misc/home-manager.nix { ref = "release-21.05"; };
  proj = import ../programs/proj.nix;

  # neovim
  efm-langserver = pkgs.callPackage ../programs/efm-ls.nix { };
  fugitive = pkgs.vimUtils.buildVimPlugin { name = "vim-fugitive"; src = builtins.fetchGit { url = "https://github.com/tpope/vim-fugitive"; ref = "master"; }; };
  numb-nvim = pkgs.vimUtils.buildVimPlugin { name = "numb-nvim"; src = builtins.fetchGit { url = "https://github.com/nacro90/numb.nvim"; ref = "master"; }; };

  zig = pkgs.callPackage ../programs/zig.nix { };
in
{
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
  '';

  imports = [ (import "${home-manager}/nixos") ];

  nixpkgs.overlays = [
    (
      import (
        builtins.fetchTarball {
          url =
            "https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz";
        }
      )
    )
  ];

  boot = {
    binfmt.emulatedSystems = [ "aarch64-linux" ];
    cleanTmpDir = true;
    kernelPackages = pkgs.linuxPackages_5_13;
    tmpOnTmpfs = true;
  };

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  console.useXkbConfig = true;

  networking.networkmanager.enable = true;

  nixpkgs.config.allowUnfree = true;

  environment.binsh = "${pkgs.dash}/bin/dash";
  environment.variables = {
    EDITOR = "vim";
    NNN_TRASH = "1";
  };
  environment.systemPackages =
    [ pkgs.neovim-nightly ]
    ++ (
      # cli
      with pkgs; [
        acpi
        atop
        bat
        bc
        bind
        buildah
        cmus
        curl
        ddcutil
        delta
        dmidecode
        dnsutils
        dust
        exa
        fd
        ffmpeg
        file
        fzf
        gh
        git
        gnupg
        gotop
        grex
        gron
        htop
        iperf3
        iputils
        jq
        keybase
        killall
        libnotify
        libsecret
        lm_sensors
        mob
        neofetch
        nixops
        nmap
        nnn
        nushell
        pciutils
        picocom
        pinentry
        pinentry-curses
        procs
        renameutils
        ripgrep
        rtorrent
        sd
        skopeo
        tailscale
        tcpdump
        tealdeer
        tig
        tmux
        tmux
        tokei
        traceroute
        trash-cli
        tree
        unzip
        usbutils
        vim
        w3m
        wget
        xdg-user-dirs
        xsv
        ydiff
        yq
        yubikey-personalization
        zip
        zoxide
      ]
    ) ++ (
      # xfce
      with pkgs.xfce; [
        orage
        parole
        ristretto
        xfce4-battery-plugin
        xfce4-clipman-plugin
        xfce4-notifyd
        xfce4-panel
        xfce4-pulseaudio-plugin
        xfce4-whiskermenu-plugin
      ]
    ) ++ (
      # gui
      with pkgs; [
        bitwarden
        chromium
        element-desktop
        firefox
        gimp
        gnome.adwaita-icon-theme
        kitty
        libreoffice
        signal-desktop
        thunderbird
        wireshark
        xclip
        xsel
      ]
    )
    ++ (
      # unfree
      with pkgs; [
        postman
        slack
        spotify
        vscode-fhs
        zoom-us
      ]
    )
    ++ (
      # self-packaged
      [
        (pkgs.callPackage fdroidcl { })
        (pkgs.callPackage gosee { })
        (pkgs.callPackage audio { })
        (pkgs.callPackage proj { })
      ]
    );

  fonts.fonts = with pkgs; [
    dejavu_fonts
    fira-code
    hack-font
    inconsolata
    liberation_ttf
    liberation_ttf
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    source-code-pro
  ];

  services.fwupd.enable = true;
  services.printing.enable = true;
  services.redshift.enable = true;
  services.dbus.packages = [ pkgs.gcr ];
  services.gnome.gnome-keyring.enable = true;
  services.udev.packages = [ pkgs.yubikey-personalization ];
  location.provider = "geoclue2";
  services.xserver = {
    layout = "us";
    xkbOptions = "ctrl:nocaps";
    xautolock.enable = true;
    desktopManager.xterm.enable = true;
    desktopManager.xfce.enable = true;
    deviceSection = ''
      Option "TearFree" "true"
    '';
  };

  security.sudo.wheelNeedsPassword = false;

  sound.enable = true;
  hardware.pulseaudio.enable = true;
  nixpkgs.config.pulseaudio = true;

  virtualisation = {
    podman.enable = true;
    podman.dockerCompat = true;
    containers.enable = true;
    containers.containersConf.settings = {
      engine = { detach_keys = "ctrl-e,ctrl-q"; };
    };
  };

  programs.adb.enable = true;
  programs.ssh.startAgent = false;

  users.users.jared = {
    description = "Jared Baur";
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "adbusers" ];
    openssh.authorizedKeys.keys = [ (import ./pubSshKey.nix) ];
  };

  home-manager.users.jared = {
    imports = [
      ../programs/bash.nix
      ../programs/git.nix
      ../programs/kitty.nix
      ../programs/ssh.nix
      ../programs/tmux.nix
    ];

    services.syncthing.enable = true;
    services.udiskie.enable = true;
    services.gpg-agent = {
      enable = true;
      enableScDaemon = true;
      enableSshSupport = true;
      defaultCacheTtl = 60480000;
      maxCacheTtl = 60480000;
      pinentryFlavor = "gnome3";
    };

    programs.direnv.enable = true;
    programs.direnv.nix-direnv.enable = true;
    programs.bat = {
      enable = true;
      config.theme = "gruvbox_dark";
    };
    programs.zsh.enable = true;
    programs.vim = {
      enable = true;
      settings = {
        hidden = true;
        expandtab = true;
      };
    };
    programs.neovim = {
      enable = true;
      package = pkgs.neovim-nightly;
      vimAlias = true;
      vimdiffAlias = true;
      plugins = with pkgs.vimPlugins; [
        commentary
        gruvbox-nvim
        lsp-colors-nvim
        nvim-autopairs
        nvim-dap
        nvim-lspconfig
        nvim-treesitter
        plenary-nvim
        repeat
        snippets-nvim
        surround
        telescope-nvim
        typescript-vim
        vim-better-whitespace
        vim-nix
        vim-rsi
        zig-vim
      ] ++ [
        fugitive
        numb-nvim
      ];
      extraPackages =
        ([ zig ]) ++ (
          with pkgs;
          [
            clang
            efm-langserver
            go
            goimports
            gopls
            luaformatter
            nixpkgs-fmt
            nodejs
            pyright
            python3
            rnix-lsp
            shellcheck
            shfmt
            sumneko-lua-language-server
            tree-sitter
            yaml-language-server
            zls
          ]
        ) ++ (
          with pkgs.nodePackages; [
            bash-language-server
            prettier
            typescript-language-server
          ]
        );
      extraConfig = ''
        lua << EOF
        -- Used in ../program/neovim/init.lua
        Sumneko_bin = "${pkgs.sumneko-lua-language-server}/bin/lua-language-server"
        Sumneko_main = "${pkgs.sumneko-lua-language-server}/extras/main.lua"
        ${builtins.readFile ../programs/neovim/init.lua}
        EOF
      '';
    };

    xdg = {
      configFile."zls.json".text = ''
        {"enable_semantic_tokens":false}
      '';
      userDirs = {
        enable = true;
        createDirectories = true;
      };
    };
  };
}
