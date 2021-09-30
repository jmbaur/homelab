{ config, pkgs, ... }:

let
  fdroidcl = pkgs.callPackage (import ../programs/fdroidcl.nix) { };
  gosee = pkgs.callPackage (import (builtins.fetchTarball "https://github.com/jmbaur/gosee/archive/main.tar.gz")) { };
  proj = pkgs.callPackage (import ../programs/proj.nix) { };
in
{
  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz;
    }))
  ];

  # nix-direnv, prevent nix shells from being wiped on garbage collection
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
  '';
  environment.pathsToLink = [
    "/share/nix-direnv"
  ];

  boot = {
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
    EDITOR = "nvim";
    NNN_TRASH = "1";
  };

  environment.systemPackages = (
    # cli
    with pkgs; [
      acpi
      alacritty
      atop
      awscli
      bat
      bc
      bind
      brightnessctl
      buildah
      cmus
      ctags
      curl
      ddcutil
      delta
      direnv
      dmidecode
      dnsutils
      dunst
      dust
      exa
      fd
      fdroidcl
      ffmpeg
      file
      firefox
      fzf
      geteltorito
      gh
      git
      gnumake
      gnupg
      go
      gopls
      gosee
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
      lm_sensors
      mob
      neofetch
      neovim-nightly
      nix-direnv
      nixops
      nixpkgs-fmt
      nmap
      nnn
      nodePackages.prettier
      nodePackages.typescript-language-server
      nodejs
      nushell
      nvme-cli
      pciutils
      picocom
      pinentry
      pinentry-curses
      podman-compose
      procs
      proj
      pyright
      python3
      renameutils
      ripgrep
      rtorrent
      sd
      shellcheck
      shfmt
      skopeo
      stow
      tailscale
      tcpdump
      tealdeer
      tig
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
      bitwarden
      chromium
      element-desktop
      firefox
      gimp
      google-chrome
      libreoffice
      pavucontrol
      postman
      signal-desktop
      slack
      spotify
      wireshark
      xclip
      xsel
      zoom-us
    ]
  );

  programs.bash = {
    vteIntegration = true;
    undistractMe.enable = true;
  };

  programs.zsh = {
    enable = true;
    vteIntegration = true;
  };

  fonts.fonts = with pkgs; [
    dejavu_fonts
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

  location.provider = "geoclue2";
  services.redshift.enable = true;

  # Yubikey GPG and SSH support
  services.udev.packages = [ pkgs.yubikey-personalization ];
  programs = {
    ssh.startAgent = false;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryFlavor = "curses";
    };
  };

  services.xserver = {
    enable = true;
    layout = "us";
    xkbOptions = "ctrl:nocaps";
    displayManager = {
      defaultSession = "none+i3";
      autoLogin.enable = true;
      autoLogin.user = "jared";
    };
    desktopManager.xterm.enable = true;
    windowManager.i3 = {
      enable = true;
      extraSessionCommands = ''
        xsetroot -solid black
      '';
    };
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

  users.users.jared = {
    description = "Jared Baur";
    extraGroups = [ "wheel" "networkmanager" "adbusers" ];
    isNormalUser = true;
    openssh.authorizedKeys.keys = [ (import ./pubSshKey.nix) ];
    shell = pkgs.bash;
  };
}
