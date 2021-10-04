{ config, pkgs, ... }:

let
  efm-langserver = import ../programs/efm-langserver { };
  fdroidcl = import ../programs/fdroidcl { };
  gosee = import (builtins.fetchTarball "https://github.com/jmbaur/gosee/archive/main.tar.gz") { };
  proj = import ../programs/proj { };
in
{
  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz;
    }))
  ];

  hardware.enableRedistributableFirmware = true;

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
      awscli2
      bat
      bc
      bind
      black
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
      efm-langserver
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
      goimports
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
      luaformatter
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
      pass
      pciutils
      picocom
      pinentry
      pinentry-curses
      podman-compose
      procs
      proj
      pwgen
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
      chromium
      element-desktop
      firefox
      gimp
      google-chrome
      libreoffice
      pavucontrol
      pinentry-gnome
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

  services.syncthing = {
    enable = true;
    user = "jared";
    group = "users";
    dataDir = "/home/jared";
    configDir = "/home/jared/.config/syncthing";
    # openDefaultPorts = true;
    declarative.overrideFolders = false;
    declarative.overrideDevices = true;
  };

  # Yubikey GPG and SSH support
  services.udev.packages = [ pkgs.yubikey-personalization ];
  services.dbus.packages = [ pkgs.gcr ];
  programs = {
    ssh.startAgent = false;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryFlavor = "gnome3";
    };
  };

  services.xserver = {
    enable = true;
    layout = "us";
    xkbOptions = "ctrl:nocaps";
    deviceSection = ''
      Option "TearFree" "true"
    '';
    displayManager = {
      defaultSession = "none+i3";
      autoLogin.enable = true;
      autoLogin.user = "jared";
    };
    desktopManager.xterm.enable = true;
    windowManager.i3 = {
      enable = true;
      extraSessionCommands = ''
        xsetroot -solid "#000000"
      '';
      extraPackages = with pkgs; [
        dmenu
        i3lock
        i3status-rust
      ];
    };
  };

  programs.xss-lock = {
    enable = true;
    lockerCommand = ''
      ${pkgs.i3lock}/bin/i3lock -c 000000
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
    extraGroups = [
      "adbusers"
      "networkmanager"
      "wheel"
      "wireshark"
    ];
    isNormalUser = true;
    openssh.authorizedKeys.keys = [ "${builtins.readFile ./publicSSHKey.txt}" ];
    shell = pkgs.bash;
  };
}
