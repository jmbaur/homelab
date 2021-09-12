{ config, pkgs, ... }:

let
  proj = pkgs.writeShellScriptBin "proj" ''
    DIR=''${PROJ_DIR:-$HOME/Projects}
    if [ ! -d $DIR ]; then
      echo "Cannot find project directory"
      exit 1
    fi
    PROJ=$(${pkgs.fd}/bin/fd -t d -H ^.git$ $DIR | xargs dirname | ${pkgs.fzf}/bin/fzf)
    if [ -z "$PROJ" ]; then
      exit 1
    fi
    TMUX_SESSION_NAME=$(basename $PROJ)
    ${pkgs.tmux}/bin/tmux new-session -d -c $PROJ -s $TMUX_SESSION_NAME
    if [ -n "$TMUX" ]; then
      ${pkgs.tmux}/bin/tmux switch-client -t $TMUX_SESSION_NAME
    else
      ${pkgs.tmux}/bin/tmux attach-session -t $TMUX_SESSION_NAME
    fi
  '';
  audio = pkgs.writeShellScriptBin "audio" ''
    case $1 in
    "sink")
      pactl set-default-sink $(pactl list sinks short | awk '{print $2}' | fzf)
      ;;
    "source")
      pactl set-default-source $(pactl list sources short | awk '{print $2}' | fzf | awk '{print $1}')
      ;;
    *)
      echo "Argument must be 'sink' or 'source'"
      exit 1
      ;;
    esac
  '';
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
  home-manager = builtins.fetchGit {
    url = "https://github.com/nix-community/home-manager";
    ref = "release-21.05";
  };
in {
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
  '';

  imports = [ (import "${home-manager}/nixos") ];

  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url =
        "https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz";
    }))
  ];

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  console.useXkbConfig = true;

  networking.networkmanager.enable = true;

  environment.binsh = "${pkgs.dash}/bin/dash";
  environment.variables = { EDITOR = "vim"; };
  environment.systemPackages = with pkgs; [
    # self-packaged
    audio
    fdroidcl
    gosee
    proj

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
    gotop
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
    neovim-nightly
    nnn
    nushell
    pciutils
    pinentry
    pinentry-curses
    procs
    pulseaudio
    renameutils
    ripgrep
    sd
    skopeo
    tcpdump
    tealdeer
    tig
    tmux
    tmux
    tokei
    traceroute
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
    alacritty
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
        vim = "nvim";
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
    home.sessionVariables = { EDITOR = "vim"; };
    home.file.".vimrc".text = ''
      color ron
      set noswapfile
      set hidden
    '';
    home.file.".Xresources".text = ''
      Xcursor.theme: Adwaita
      XTerm.termName: xterm-256color
      XTerm.vt100.locale: false
      XTerm.vt100.utf8: true
      XTerm.vt100.metaSendsEscape: true
      XTerm.vt100.backarrowKey: false
      XTerm.vt100.ttyModes: erase ^?
      XTerm.vt100.bellIsUrgent: true
      *.faceName: Hack:size=14:antialias=true
    '';
    home.file.".icons/default/index.theme".text = ''
      [icon theme] 
      Inherits=Adwaita
    '';
    home.file.".tmux.conf".source = ./tmux.conf;
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
      # configFile."gtk-3.0/settings.ini".text = ''
      #   [Settings]
      #   gtk-key-theme-name = Emacs
      #   gtk-cursor-theme-name=Adwaita
      #   gtk-application-prefer-dark-theme = true
      # '';
      configFile."dunst/dunstrc".source = ./dunstrc;
      configFile."kitty/kitty.conf".source = ./kitty.conf;
      configFile."alacritty/alacritty.yml".source = ./alacritty.yml;
      configFile."i3/config".source = ./i3config;
      configFile."i3status-rust/config.toml".source = ./i3status.toml;
      configFile."git/config".source = ./gitconfig;
      configFile."nvim/init.lua".source = ./init.lua;

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
  };
}
