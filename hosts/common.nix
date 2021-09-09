{ config, pkgs, ... }:

let
  proj = pkgs.writeShellScriptBin "proj" ''
    DIR=''${PROJ_DIR:-$HOME/Projects}
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
    ref = "release-21.05";
  };
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

  environment.variables = { EDITOR = "vim"; };
  environment.systemPackages = with pkgs; [
    proj
    audio
    gosee
    fdroidcl

    pciutils
    usbutils
    wget
    curl
    tmux
    vim
    nixfmt
    git
    bc
    tree
    file
    zip
    unzip
    bind
    nnn
    neovim-nightly
    tig
    jq
    htop
    gotop
    w3m
    iperf3
    fzf
    ydiff
    gnupg
    gh
    pinentry
    pinentry-curses
    yubikey-personalization
    lm_sensors
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

    tree-sitter
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

    dunst
    scrot
    xsel
    xclip
    sxiv
    mpv
    zathura
    gnome.adwaita-icon-theme
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
    vscode-fhs
  ];

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

  services.fwupd.enable = true;
  services.printing.enable = true;
  services.redshift.enable = true;
  location.provider = "geoclue2";
  services.xserver = {
    displayManager.lightdm = {
      enable = true;
      background = pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath;
    };
    deviceSection = ''
      Option "TearFree" "true"
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

  virtualisation.podman.enable = true;
  virtualisation.podman.dockerCompat = true;

  programs.adb.enable = true;
  programs = { ssh.startAgent = false; };
  environment.shellInit = ''
    gpg-connect-agent /bye
    export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
  '';

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
}
