{ config, pkgs, ... }:

{
  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz;
    }))
  ];

  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
  '';

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
      dmidecode
      dnsutils
      dunst
      dust
      exa
      fd
      ffmpeg
      file
      firefox
      fzf
      geteltorito
      gh
      git
      gnumake
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
      lm_sensors
      mob
      neofetch
      neovim-nightly
      nixops
      nmap
      nnn
      nushell
      nvme-cli
      pciutils
      picocom
      pinentry
      pinentry-curses
      podman-compose
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
      tokei
      traceroute
      trash-cli
      python3
      shellcheck
      shfmt
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
      libreoffice
      google-chrome
      signal-desktop
      wireshark
      xclip
      xsel
      postman
      slack
      spotify
      zoom-us
    ]
  ) ++ (
    with pkgs;
    [
      go
      gopls
      nixpkgs-fmt
      nodePackages.prettier
      nodePackages.typescript-language-server
      nodejs
    ]
  );


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
  services.redshift.enable = true;

  # Yubikey GPG and SSH support
  services.udev.packages = [ pkgs.yubikey-personalization ];
  environment.shellInit = ''
    export GPG_TTY="$(tty)"
    gpg-connect-agent /bye
    export SSH_AUTH_SOCK="/run/user/$UID/gnupg/S.gpg-agent.ssh"
  '';

  programs = {
    ssh.startAgent = false;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryFlavor = "curses";
    };
  };

  location.provider = "geoclue2";
  services.xserver = {
    enable = true;
    layout = "us";
    xkbOptions = "ctrl:nocaps";
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
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "adbusers" ];
    openssh.authorizedKeys.keys = [ (import ./pubSshKey.nix) ];
  };
}
