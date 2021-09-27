{ config, pkgs, ... }:

let
  audio = import ../programs/audio.nix;
  efm-langserver = pkgs.callPackage ../programs/efm-ls.nix { };
  fdroidcl = import ../programs/fdroidcl.nix;
  fugitive = pkgs.vimUtils.buildVimPlugin { name = "vim-fugitive"; src = builtins.fetchGit { url = "https://github.com/tpope/vim-fugitive"; ref = "master"; }; };
  gosee = import (builtins.fetchGit { "url" = "https://github.com/jmbaur/gosee.git"; ref = "9fdd41bd6061bd9a8a8daa69166e4f5007f2584a"; });
  home-manager = import ../misc/home-manager.nix { ref = "release-21.05"; };
  kommentary = pkgs.vimUtils.buildVimPlugin { name = "kommentary"; src = builtins.fetchGit { url = "https://github.com/b3nj5m1n/kommentary"; ref = "main"; }; };
  numb-nvim = pkgs.vimUtils.buildVimPlugin { name = "numb-nvim"; src = builtins.fetchGit { url = "https://github.com/nacro90/numb.nvim"; ref = "master"; }; };
  proj = import ../programs/proj.nix;
  tempus-themes = builtins.fetchGit { url = "https://gitlab.com/protesilaos/tempus-themes"; ref = "master"; };
  tempus-themes-vim = pkgs.vimUtils.buildVimPlugin { name = "tempus-themes-vim"; src = builtins.fetchGit { url = "https://gitlab.com/protesilaos/tempus-themes-vim"; ref = "master"; }; };
  unstable = import (builtins.fetchTarball "https://github.com/nixos/nixpkgs/tarball/master") { config = config.nixpkgs.config; };
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
  environment.systemPackages = (
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
      file
      fzf
      gh
      git
      gnupg
      gomuks
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
      pulseaudio
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
    # gui
    with pkgs; [
      alacritty
      bitwarden
      brave
      chromium
      dunst
      element-desktop
      firefox
      freetube
      gimp
      gnome.adwaita-icon-theme
      kitty
      libreoffice
      mpv
      scrot
      signal-desktop
      sxiv
      wireshark
      xclip
      xsel
      zathura
    ]
  )
  ++ (
    # unfree
    with pkgs; [
      google-chrome
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
    displayManager.lightdm = {
      enable = true;
      background =
        pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath;
    };
    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [ i3lock i3status-rust dmenu ];
      extraSessionCommands = ''
        xsetroot -solid "#1a1a1a"
      '';
    };
    deviceSection = ''
      Option "TearFree" "true"
    '';
  };

  programs.xss-lock = {
    enable = true;
    lockerCommand = ''
      ${pkgs.i3lock}/bin/i3lock -c 1a1a1a
    '';
  };

  security.sudo.wheelNeedsPassword = false;
  security.rtkit.enable = true;

  sound.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    media-session.config.bluez-monitor.rules = [
      {
        # Matches all cards
        matches = [{ "device.name" = "~bluez_card.*"; }];
        actions = {
          "update-props" = {
            "bluez5.reconnect-profiles" = [ "hfp_hf" "hsp_hs" "a2dp_sink" ];
            # mSBC is not expected to work on all headset + adapter combinations.
            "bluez5.msbc-support" = true;
            # SBC-XQ is not expected to work on all headset + adapter combinations.
            "bluez5.sbc-xq-support" = true;
          };
        };
      }
      {
        matches = [
          # Matches all sources
          {
            "node.name" = "~bluez_input.*";
          }
          # Matches all outputs
          { "node.name" = "~bluez_output.*"; }
        ];
        actions = { "node.pause-on-idle" = false; };
      }
    ];
  };

  virtualisation = {
    podman.enable = true;
    podman.dockerCompat = true;
    containers.enable = true;
    containers.containersConf.settings = {
      engine = { detach_keys = "ctrl-e,ctrl-q"; };
    };
  };

  programs.adb.enable = true;
  programs = { ssh.startAgent = false; };

  users.users.jared = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "adbusers" ];
    openssh.authorizedKeys.keys = [ (import ./pubSshKey.nix) ];
  };

  home-manager.users.jared = {
    imports = [
      ../programs/rofi.nix
      ../programs/ssh.nix
      ../programs/i3status-rust.nix
      ../programs/i3.nix
    ];
    services.clipmenu.enable = true;
    services.gpg-agent = {
      enable = true;
      enableScDaemon = true;
      enableSshSupport = true;
      defaultCacheTtl = 60480000;
      maxCacheTtl = 60480000;
      pinentryFlavor = "gnome3";
    };
    services.syncthing.enable = true;
    services.udiskie.enable = true;
    programs.direnv.enable = true;
    programs.direnv.nix-direnv.enable = true;
    programs.zsh = {
      enable = true;
    };
    programs.bash = {
      enable = true;
      enableVteIntegration = true;
      shellAliases = {
        ls = "exa";
        ll = "exa -hl";
        la = "exa -ahl";
        grep = "grep --color=auto";
      };
      initExtra = ''
        gpg-connect-agent /bye
        export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
      '';
      bashrcExtra = ''
        eval "$(${pkgs.zoxide}/bin/zoxide init bash)"
      '';
    };
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
        haskell-vim
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
        kommentary
        numb-nvim
        tempus-themes-vim
      ];
      extraPackages = (
        with pkgs;
        [
          clang
          efm-langserver
          go
          goimports
          gopls
          haskell-language-server
          luaformatter
          nixpkgs-fmt
          nodejs
          pyright
          python3
          rnix-lsp
          shellcheck
          shfmt
          stylish-haskell
          sumneko-lua-language-server
          tree-sitter
          yaml-language-server
        ]
      ) ++ (
        with pkgs.nodePackages; [
          bash-language-server
          prettier
          typescript-language-server
        ]
      ) ++ (with unstable;[ zig zls ]);
      extraConfig = ''
        lua << EOF
        -- Used in ../programs/neovim/init.lua
        Sumneko_bin = "${pkgs.sumneko-lua-language-server}/bin/lua-language-server"
        Sumneko_main = "${pkgs.sumneko-lua-language-server}/extras/main.lua"
        ${builtins.readFile ../programs/neovim/init.lua}
        EOF
      '';
    };
    xresources.properties = {
      "*.faceName" = "Hack:size=14:antialias=true";
      "XTerm.termName" = "xterm-256color";
      "XTerm.vt100.backarrowKey" = false;
      "XTerm.vt100.bellIsUrgent" = true;
      "XTerm.vt100.locale" = false;
      "XTerm.vt100.metaSendsEscape" = true;
      "XTerm.vt100.ttyModes" = "erase ^?";
      "XTerm.vt100.utf8" = true;
      "Xcursor.theme" = "Adwaita";
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
      sensibleOnTop = false;
      terminal = "screen-256color";
      plugins = with pkgs.tmuxPlugins; [ logging resurrect yank ];
      extraConfig = ''
        set -g set-clipboard on
        set -g renumber-windows on
        set-option -g focus-events on
        set-option -ga terminal-overrides ',xterm-256color:Tc'
      '';
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
      delta = {
        enable = true;
        options = {
          syntax-theme = "gruvbox-dark";
        };
      };
      ignores = [ "*~" "*.swp" ];
      userEmail = "jaredbaur@fastmail.com";
      userName = "Jared Baur";
      extraConfig = { pull = { rebase = false; }; };
    };
    programs.bat = {
      enable = true;
      config = {
        theme = "gruvbox-dark";
      };
    };
    programs.kitty = {
      enable = true;
      font = {
        package = pkgs.hack-font;
        name = "Hack";
        size = 14;
      };
      settings = {
        copy_on_select = true;
        enable_audio_bell = false;
        term = "xterm-256color";
        update_check_interval = 0;
      };
      extraConfig = ''
        include ${tempus-themes}/kitty/tempus_night.conf
      '';
    };
    gtk = {
      enable = true;
      gtk3.extraConfig = {
        gtk-theme-name = "Adwaita";
        gtk-cursor-theme-name = "Adwaita";
        gtk-icon-theme-name = "Adwaita";
        gtk-key-theme-name = "Emacs";
        gtk-application-prefer-dark-theme = true;
      };
    };
    xdg = {
      mime.enable = true;
      configFile."zls.json".text = ''
        {"enable_semantic_tokens":false}
      '';
      userDirs = {
        enable = true;
        createDirectories = true;
      };
      mimeApps = {
        enable = true;
        defaultApplications = {
          "image/png" = [ "sxiv.desktop" ];
          "image/jpg" = [ "sxiv.desktop" ];
          "image/jpeg" = [ "sxiv.desktop" ];
          "video/mp4" = [ "mpv.desktop" ];
          "video/webm" = [ "mpv.desktop" ];
          "application/pdf" = [ "org.pwmt.zathura.desktop" ];
          "text/html" = [ "firefox.desktop" ];
          "x-scheme-handler/http" = [ "firefox.desktop" ];
          "x-scheme-handler/https" = [ "firefox.desktop" ];
          "x-scheme-handler/about" = [ "firefox.desktop" ];
          "x-scheme-handler/unknown" = [ "firefox.desktop" ];
        };
      };
    };
    services.dunst = {
      enable = true;
      settings = {
        global = {
          font = "DejaVu Sans Mono 10";
          geometry = "300x5-30+20";
          notification_height = 0;
          separator_height = 2;
          padding = 8;
          horizontal_padding = 8;
          text_icon_padding = 0;
          frame_width = 3;
          frame_color = "#aaaaaa";
          separator_color = "frame";
          sort = "yes";
          line_height = 0;
          markup = "full";
          format = ''
            <b>%s</b>
            %b'';
          alignment = "left";
          vertical_alignment = "center";
          icon_position = "left";
          monitor = 0;
          follow = "mouse";
          progress_bar = true;
          progress_bar_height = 10;
          progress_bar_frame_width = 1;
          progress_bar_min_width = 150;
          progress_bar_max_width = 300;
          indicate_hidden = "yes";
          shrink = "no";
          transparency = 0;
          idle_threshold = 120;
          show_age_threshold = 60;
          word_wrap = "yes";
          ellipsize = "middle";
          ignore_newline = "no";
          stack_duplicates = true;
          hide_duplicate_count = false;
          show_indicators = "yes";
          min_icon_size = 0;
          max_icon_size = 32;
          # icon_path =
          #   "${pkgs.gnome.adwaita-icon-theme}/share/icons/Adwaita/16x16/status/:${pkgs.gnome.adwaita-icon-theme}/share/icons/Adwaita/16x16/devices/";
          sticky_history = "yes";
          history_length = 20;
          dmenu =
            ''${pkgs.dmenu}/bin/dmenu -fn "DejaVu Sans Mono:10" -p dunst:'';
          browser = "${pkgs.firefox}/bin/firefox -new-tab";
          always_run_script = true;
          title = "Dunst";
          class = "Dunst";
          startup_notification = false;
          verbosity = "mesg";
          corner_radius = 0;
          ignore_dbusclose = false;
          force_xwayland = false;
          force_xinerama = false;
          mouse_left_click = "close_current";
          mouse_middle_click = "do_action, close_current";
          mouse_right_click = "close_all";
        };
        experimental = { per_monitor_dpi = false; };
        urgency_low = {
          background = "#222222";
          foreground = "#888888";
          timeout = 10;
        };
        urgency_normal = {
          background = "#285577";
          foreground = "#ffffff";
          timeout = 10;
        };
        urgency_critical = {
          background = "#900000";
          foreground = "#ffffff";
          frame_color = "#ff0000";
          timeout = 0;
        };
      };
    };
  };
}
