{ config, lib, pkgs, ... }:
with lib;
{
  imports = [ ./hardware-configuration.nix ];

  nix = {
    # Enable flakes and prevent nix shells from being wiped on garbage
    # collection.
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
  };
  environment.pathsToLink = [ "/share/nix-direnv" ];

  # sudo systemd-cryptenroll --fido2-device=auto /dev/nvme0n1p1
  environment.etc."crypttab".text = ''
    cryptlvm /dev/nvme0n1p1 - fido2-device=auto
  '';
  boot = {
    binfmt.emulatedSystems = [ "aarch64-linux" ]; # allow building for RPI4
    extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];

    initrd.luks.devices.cryptlvm = {
      allowDiscards = true;
      device = "/dev/disk/by-uuid/91d0d31c-9669-4476-9b46-66680f312a3c";
      preLVM = true;
      fallbackToPassword = true;
    };
    kernelPackages = pkgs.linuxPackages_5_15;
    kernelParams = [ "amdgpu.backlight=0" "acpi_backlight=none" ];
    loader = { systemd-boot.enable = true; efi.canTouchEfiVariables = true; };
  };

  hardware = {
    bluetooth.enable = true;
    cpu.amd.updateMicrocode = true;
    enableRedistributableFirmware = true;
  };

  networking.hostName = "beetroot";
  networking.networkmanager.enable = true;
  time.timeZone = "America/Los_Angeles";

  environment.variables.NNN_TRASH = "1";

  nixpkgs.config.allowUnfree = true;

  custom = {
    git.enable = true;
    sway.enable = false;
    neovim.enable = true;
    pipewire.enable = true;
    tmux.enable = true;
  };

  fonts.fonts = with pkgs; [
    recursive
    dejavu_fonts
    dina-font
    hack-font
    inconsolata
    iosevka
    liberation_ttf
    noto-fonts
    noto-fonts-emoji
    proggyfonts
    source-code-pro
    source-sans-pro
    spleen
    tewi-font
  ];

  services.xserver = {
    enable = true;
    layout = "us";
    xkbOptions = "ctrl:nocaps";
    deviceSection = ''
      Option "TearFree" "true"
    '';
    libinput = {
      enable = true;
      touchpad = { accelProfile = "flat"; tapping = true; naturalScrolling = true; };
    };
    displayManager = {
      lightdm.background = pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath;
      defaultSession = "none+i3";
      autoLogin = { enable = true; user = "jared"; };
      sessionCommands = ''
        ${pkgs.xorg.xrdb}/bin/xrdb -merge <<EOF
          Xcursor.theme: Adwaita
        EOF
      '';
    };
    windowManager.i3 = {
      enable = true;
      configFile = pkgs.callPackage ../../config/i3/config.nix { };
      extraSessionCommands = ''
        ${pkgs.hsetroot}/bin/hsetroot -cover ${pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath}
      '';
    };
  };
  services.greetd = {
    enable = false;
    settings = {
      default_session = {
        command =
          let
            tuigreet = "${pkgs.greetd.tuigreet}/bin/tuigreet";
            startx = "${pkgs.xorg.xinit}/bin/startx";
            i3 = "${pkgs.i3}/bin/i3";
            i3-config = pkgs.callPackage ../../config/i3/config.nix { };
          in
          "${tuigreet} --time --asterisks --cmd '${startx} ${i3} -c ${i3-config}'";
      };
    };
  };
  programs.xss-lock = {
    enable = true;
    lockerCommand = "${pkgs.xsecurelock}/bin/xsecurelock";
    extraOptions = [
      "-n"
      "${pkgs.xsecurelock}/libexec/xsecurelock/dimmer"
      "-l"
    ];
  };
  environment.etc."xdg/gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-application-prefer-dark-theme=1
    gtk-theme-name=Adwaita
    gtk-icon-theme-name=Adwaita
    gtk-cursor-theme-name=Adwaita
    gtk-key-theme-name=Emacs
  '';
  environment.variables.XCURSOR_PATH = mkForce [ "${pkgs.gnome.adwaita-icon-theme}/share/icons" ];

  location.provider = "geoclue2";
  services.redshift.enable = true;
  services.autorandr.enable = true;
  services.autorandr.defaultTarget = "laptop";
  services.clipmenu.enable = true;
  services.fwupd.enable = true;
  services.printing.enable = true;
  services.avahi.enable = true;
  services.avahi.nssmdns = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  services.syncthing = {
    enable = false;
    user = "jared";
    group = "users";
    dataDir = "/home/jared";
    configDir = "/home/jared/.config/syncthing";
    openDefaultPorts = true;
    # declarative.overrideFolders = false;
    # declarative.overrideDevices = true;
  };

  environment.systemPackages = with pkgs; [
    age
    alacritty
    awscli2
    bat
    bitwarden
    brightnessctl
    buildah
    chromium
    direnv
    discord
    drawio
    dunst
    dust
    element-desktop
    exa
    fd
    fdroidcl
    ffmpeg-full
    firefox
    fzf
    geteltorito
    gh
    gimp
    git
    git-get
    gnupg
    gosee
    gotop
    grex
    gron
    htmlq
    imv
    jq
    keybase
    kitty
    libreoffice
    librespeed-cli
    mob
    mosh
    mpv
    nix-direnv
    nix-prefetch-docker
    nix-tree
    nixopsUnstable
    nixos-generators
    nnn
    nushell
    nvme-cli
    openssl
    p
    pa-switch
    pass
    pass-git-helper
    patchelf
    pavucontrol
    picocom
    pinentry-gnome
    plan9port
    pwgen
    renameutils
    ripgrep
    rtorrent
    scrot
    sd
    signal-desktop
    skopeo
    sl
    slack
    speedtest-cli
    spotify
    start-recording
    stop-recording
    stow
    tailscale
    tcpdump
    tea
    tealdeer
    thunderbird
    tig
    tokei
    trash-cli
    unzip
    usbutils
    vscode-with-extensions
    wireshark
    xdg-user-dirs
    xdg-utils
    xsv
    ydiff
    yq
    yubikey-personalization
    zathura
    zip
    zoom-us
    zoxide
  ];

  environment.variables.HISTCONTROL = "ignoredups";
  programs.bash = {
    vteIntegration = true;
    undistractMe.enable = true;
    shellAliases = { grep = "grep --color=auto"; };
    enableLsColors = true;
    enableCompletion = true;
    interactiveShellInit = ''
      eval "$(${pkgs.direnv}/bin/direnv hook bash)"
    '';
  };

  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = false;
    shellAliases = { grep = "grep --color=auto"; };
    promptInit = ''
      PS1="%F{cyan}%n@%m%f:%F{green}%c%f %% "
    '';
    # Prevent zsh-newuser-install from showing
    shellInit = ''
      zsh-newuser-install() { :; }
      bindkey -e
      bindkey \^U backward-kill-line
    '';
    interactiveShellInit = ''
      eval "$(${pkgs.direnv}/bin/direnv hook zsh)"
    '';
  };

  system.userActivationScripts.nix-direnv.text =
    let
      direnvrc = pkgs.writeText "direnvrc" ''
        source ${pkgs.nix-direnv}/share/nix-direnv/direnvrc
      '';
    in
    ''
      ln -sf ${direnvrc} ''${HOME}/.direnvrc
    '';


  services.udev.packages = [ pkgs.yubikey-personalization ];
  programs.ssh.startAgent = true;
  programs.wireshark.enable = true;
  programs.adb.enable = true;

  users.users.jared = {
    description = "Jared Baur";
    isNormalUser = true;
    extraGroups = [ "adbusers" "networkmanager" "wheel" "wireshark" ];
    initialPassword = "helloworld";
  };
  security.sudo.wheelNeedsPassword = false;

  virtualisation = {
    containers = {
      enable = true;
      containersConf.settings.engine.detach_keys = "ctrl-e,ctrl-q";
    };
    podman = { enable = true; dockerCompat = true; };
    libvirtd.enable = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}

