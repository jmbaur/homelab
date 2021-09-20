{ config, pkgs, ... }:

let
  gosee = pkgs.buildGoModule {
    name = "gosee";
    src = builtins.fetchGit { url = "https://github.com/jmbaur/gosee.git"; };
    vendorSha256 = "07q9war08k1pqg5hz6pvc1pf1s9k70jgfwp7inxygh9p4k7lwnr1";
    runVend = true;
  };
  fdroidcl = pkgs.buildGoModule {
    name = "fdroidcl";
    src = builtins.fetchGit { url = "https://github.com/mvdan/fdroidcl.git"; };
    vendorSha256 = "11q0gy3wfjaqyfj015yw3wfz2j1bsq6gchjhjs6fxfjmb77ikwjb";
    runVend = true;
  };
  home-manager = import ./home-manager.nix { ref = "release-21.05"; };
in
{
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
  '';

  imports =
    [
      (import "${home-manager}/nixos")
      ../programs/neovim/neovim.nix
      ../weechat.nix
      ../programs/audio.nix
      ..programs/proj.nix
      ../programs/i3.nix
      ../programs/i3status-rust.nix
    ];

  boot = {
    kernelPackages = pkgs.linuxPackages_5_13;
    cleanTmpDir = true;
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
  environment.systemPackages = with pkgs; [
    # self-packaged
    fdroidcl
    gosee

    # cli
    acpi
    atop
    bat
    bc
    bind
    buildah
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
    grex
    gron
    htop
    iperf3
    iputils
    jq
    keybase
    killall
    libsecret
    lm_sensors
    neofetch
    nixops
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
    weechat
    wget
    xdg-user-dirs
    xsv
    ydiff
    yq
    yubikey-personalization
    zip
    zoxide

    # programming utils
    clang
    go
    gopls
    haskell-language-server
    luaformatter
    nixfmt
    nodePackages.bash-language-server
    nodePackages.typescript-language-server
    nodejs
    pyright
    python3
    rnix-lsp
    shellcheck
    shfmt
    stylish-haskell
    tree-sitter
    yaml-language-server

    # gui
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

    # unfree
    google-chrome
    slack
    spotify
    vscode-fhs
    zoom-us
  ];

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
        xsetroot -solid "#222222"
      '';
    };
    deviceSection = ''
      Option "TearFree" "true"
    '';
  };

  programs.xss-lock = {
    enable = true;
    lockerCommand = ''
      ${pkgs.i3lock}/bin/i3lock -c 222222
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
        matches = [ { "device.name" = "~bluez_card.*"; } ];
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
        PS1="\W $ "
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
    home.file.".icons/default/index.theme".text = ''
      [icon theme] 
      Inherits=Adwaita
    '';
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
      terminal = "tmux-256color";
      plugins = with pkgs.tmuxPlugins; [
        yank
        resurrect
        logging
      ];
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
      delta.enable = true;
      ignores = [ "*~" "*.swp" ];
      userEmail = "jaredbaur@fastmail.com";
      userName = "Jared Baur";
      extraConfig = {
        pull = {
          rebase = false;
        };
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
        };
      };
    };
  };
}
