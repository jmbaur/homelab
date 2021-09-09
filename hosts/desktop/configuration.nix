{ config, pkgs, ... }:

let
  proj = pkgs.writeShellScriptBin "proj" ''
    DIR=$HOME/Projects
    if [ -n "$PROJ_DIR" ]; then
      DIR=$PROJ_DIR
    fi
    if [ ! -d $DIR ]; then
      echo "Cannot find project directory"
      exit 1
    fi
    PROJ=$(find $DIR -type d -name .git | xargs dirname | ${pkgs.fzf}/bin/fzf)
    if [ -z "$PROJ" ];then
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
    rev = "9f2b766d0f46fcc87881531e6a86eba514b8260d";
    ref = "release-21.05";
  };
in
{
  imports = [ ./hardware-configuration.nix (import "${home-manager}/nixos") ];

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

  nix.nixPath = [
    "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
    "nixos-config=/home/jared/Projects/nixos-configs/hosts/thinkpad/configuration.nix"
    "/nix/var/nix/profiles/per-user/root/channels"
  ];
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
  '';

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_5_13;
  boot.kernelModules = [ "i2c-dev" ];

  networking.hostName = "desktop";

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp3s0.useDHCP = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Enable the X11 windowing system.
  services.xserver = {
    layout = "us";
    enable = true;
    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        i3lock
        i3status-rust
        dmenu
        dunst
        scrot
        xsel
        xclip
        sxiv
        mpv
        zathura
        gnome.adwaita-icon-theme
      ];
      extraSessionCommands = ''
        xsetroot -solid black
      '';
    };
    deviceSection = ''
      Option "TearFree" "true"
    '';
  };

  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    hack-font
    source-code-pro
    inconsolata
    liberation_ttf
    dejavu_fonts
    liberation_ttf
    fira-code
  ];

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  security.sudo.wheelNeedsPassword = false;
  users.users.jared = {
    isNormalUser = true;
    extraGroups = [ "wheel" "adbusers" ];
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
        grep = "grep --color=auto";
      };
      bashrcExtra = ''
        eval "$(${pkgs.starship}/bin/starship init bash)"
        eval "$(${pkgs.zoxide}/bin/zoxide init bash)"
      '';
    };
    home.sessionVariables = { EDITOR = "vim"; };
    home.file.".vimrc".text = ''
      set noswapfile
      set hidden
      set nu rnu
    '';
    home.file.".Xresources".text = ''
      Xcursor.theme: Adwaita
      XTerm.termName: xterm-256color
      XTerm.vt100.locale: false
      XTerm.vt100.utf8: true
      XTerm.vt100.metaSendsEscape: true
      XTerm.vt100.backarrowKey: false
      XTerm.vt100.ttyModes: erase ^?
      XTerm.vt100.faceName: Hack:size=14:antialias=true
      XTerm.vt100.bellIsUrgent: true
    '';
    home.file.".icons/default/index.theme".text = ''
      [icon theme] 
      Inherits=Adwaita
    '';
    home.file.".tmux.conf".source = ./tmux.conf;
    xdg.configFile."gtk-3.0/settings.ini".text = ''
      [Settings]
      gtk-key-theme-name = Emacs
      gtk-cursor-theme-name=Adwaita
      gtk-application-prefer-dark-theme = true
    '';
    xdg.configFile."dunst/dunstrc".source = ./dunstrc;
    xdg.configFile."containers/containers.conf".text = ''
      [engine]
      detach_keys="ctrl-q,ctrl-q"
    '';
    xdg.configFile."kitty/kitty.conf".source = ./kitty.conf;
    xdg.configFile."kitty/GruvboxMaterialDarkMedium.conf".source =
      ./GruvboxMaterialDarkMedium.conf;
    xdg.configFile."i3/config".source = ./i3config;
    xdg.configFile."i3status-rust/config.toml".source = ./i3status.toml;
    xdg.configFile."git/config".source = ./gitconfig;
    xdg.configFile."nvim/init.lua".source = ./init.lua;
  };

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    proj
    audio
    gosee
    fdroidcl

    vim
    neovim-nightly
    git
    tig
    tmux
    curl
    jq
    wget
    htop
    nnn
    bc
    w3m
    tree
    file
    zip
    unzip
    bind
    iperf3
    fzf
    ydiff
    gnupg
    pinentry
    pinentry-curses
    yubikey-personalization
    nixfmt
    lm_sensors
    nvme-cli
    ddcutil
    pulseaudio
    xdg-user-dirs
    libsecret
    skopeo
    buildah
    keybase
    gomuks

    fd
    starship
    ripgrep
    zoxide
    xsv
    bat
    exa
    procs
    sd
    dust
    tokei
    grex
    delta
    nushell
    tealdeer

    kitty
    bitwarden
    signal-desktop
    element-desktop
    gimp
    freetube
    firefox
    chromium
    brave
    libreoffice

    spotify
    zoom-us
    slack
    google-chrome
    _1password-gui
    vscode-fhs

    shfmt
    shellcheck
    go
    nodejs
    python3
    clang
    gopls
    pyright
    rnix-lsp
    yaml-language-server
    haskell-language-server
    nodePackages.typescript-language-server
    nodePackages.bash-language-server
  ];

  environment.shellInit = ''
    gpg-connect-agent /bye
    export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
  '';

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.xss-lock = {
    enable = true;
    lockerCommand = ''
      ${pkgs.i3lock}/bin/i3lock -c 000000
    '';
  };
  programs = { ssh.startAgent = false; };
  programs.adb.enable = true;

  virtualisation.podman.enable = true;
  virtualisation.podman.dockerCompat = true;

  # List services that you want to enable:
  services.udev.extraRules = ''KERNEL=="i2c-[0-9]*", GROUP+="users"'';

  services.dbus.packages = [ pkgs.gcr ];
  services.gnome.gnome-keyring.enable = true;

  services.pcscd.enable = false;
  services.udev.packages = with pkgs; [ yubikey-personalization ];

  location.latitude = 33.0;
  location.longitude = -118.0;
  services.redshift.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}
