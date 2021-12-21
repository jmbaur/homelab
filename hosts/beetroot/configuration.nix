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

  boot = {
    binfmt.emulatedSystems = [ "aarch64-linux" ]; # allow building for RPI4
    extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];

    initrd.luks = {
      fido2Support = true;
      devices.cryptlvm = {
        fido2 = {
          credential = pkgs.lib.concatStringsSep "," [
            "c4c1c74167f8eeab98b2659b22d9a60654253b7882243820550fe67b66bb5fb8d46e90ff39733fdb6b03d7cbedc4a6b2"
            "f217ebbfb939aaaf0e65a811f639ea221c63319e0eba8f5df3279d55060cc6413c5e198c2146d4709f88e9a94a78e3a8"
          ];
          passwordLess = true; # no salt
          askForPin = true;
        };
        allowDiscards = true;
        device = "/dev/disk/by-uuid/91d0d31c-9669-4476-9b46-66680f312a3c";
        preLVM = true;
      };
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


  nixpkgs.config.allowUnfree = true;

  custom = {
    git.enable = true;
    pipewire.enable = true;
    tmux.enable = true;
    neovim.enable = true;
  };

  environment.variables.NNN_TRASH = "1";

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
          Xcursor.size: 24
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
    extraOptions = [ "-n" "${pkgs.xsecurelock}/libexec/xsecurelock/dimmer" "-l" ];
  };
  environment.variables.XCURSOR_PATH = mkForce [ "${pkgs.gnome.adwaita-icon-theme}/share/icons" ];
  environment.etc."xdg/gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-key-theme-name=Emacs
    gtk-theme-name=Adwaita
    gtk-application-prefer-dark-theme=1
    gtk-icon-theme-name=Adwaita
    gtk-cursor-theme-name=Adwaita
    gtk-cursor-theme-size=24
  '';

  xdg.portal.enable = true;
  services.flatpak.enable = true;
  services.autorandr.enable = true;
  services.autorandr.defaultTarget = "laptop";
  environment.etc."xdg/autorandr/dock/config".source = ./autorandr/dock/config;
  environment.etc."xdg/autorandr/dock/setup".source = ./autorandr/dock/setup;
  environment.etc."xdg/autorandr/laptop/config".source = ./autorandr/laptop/config;
  environment.etc."xdg/autorandr/laptop/setup".source = ./autorandr/laptop/setup;
  environment.etc."xdg/autorandr/postswitch".source = "${(pkgs.writeShellScriptBin "autorandr-postswitch" ''
    ${pkgs.hsetroot}/bin/hsetroot -cover ${pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath}
    ${pkgs.libnotify}/bin/notify-send "Autorandr" "Profile switched"
  '')}/bin/autorandr-postswitch";

  location.provider = "geoclue2";
  services.redshift.enable = true;
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
    brightnessctl
    buildah
    direnv
    discord
    drawio
    dunst
    dust
    exa
    fd
    fdroidcl
    ffmpeg-full
    fido2luks
    firefox # TODO(jared): delete in favor of flatpak
    fzf
    geteltorito
    gh
    git
    git-get
    gosee
    gotop
    grex
    gron
    htmlq
    imv
    jq
    keybase
    kitty
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
    picocom
    pinentry-gnome
    plan9port
    pstree
    pwgen
    renameutils
    ripgrep
    rtorrent
    scrot
    sd
    skopeo
    sl
    speedtest-cli
    start-recording
    stop-recording
    stow
    tailscale
    tcpdump
    tea
    tealdeer
    tig
    tokei
    trash-cli
    unzip
    usbutils
    ventoy-bin
    vim
    xdg-user-dirs
    xdg-utils
    xsv
    ydiff
    yq
    yubikey-manager
    yubikey-personalization
    zathura
    zip
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


  services.pcscd.enable = false;
  services.udev.packages = with pkgs; [
    yubikey-personalization
    yubikey-manager
  ];
  programs.ssh.startAgent = true;
  programs.gnupg.agent = {
    enable = true;
    pinentryFlavor = "gtk2";
  };
  programs.wireshark.enable = true;
  programs.adb.enable = true;

  users.users.jared = {
    description = "Jared Baur";
    isNormalUser = true;
    extraGroups = [
      "adbusers"
      "libvirtd"
      "networkmanager"
      "wheel"
      "wireshark"
    ];
    initialPassword = "helloworld";
  };
  security.sudo.wheelNeedsPassword = true;
  security.pam = {
    u2f = {
      enable = true;
      cue = true;
      # generated with `pamu2fcfg`
      authFile = pkgs.writeText "u2f-authfile" (pkgs.lib.concatStringsSep ":" [
        "jared"
        "uBcyq24C/03R9XDcANHHbIRBVwnVy4+OZ5GCYfpGMqE9796kd+Jkzr+Eaigdrv8yIuBYVtX0myQgCs9leTjf5A==,j94fLX44pik4JLmo72d22uuM3mUEP9yQmvOTXotGNkgNzPWV9aMz5zHFnhEL4gKyIGSxvr/RYg7eI+DCeoxMBg==,es256,+presence"
        "NMlszg4/i0xAOtisiybK2V0nVytHo/iqtaYFQn1SeJgEDalkP/1YX2yE53eUMRUmiUcHz3CvIGyFjvyNUXzgPQ==,01T5an89gTXEmCxt0tQzSIG2p1U/GgRfFuPir41lZQMiedsYfFDNLeAxuc0+Qp5L5ZPFHzD6fGEVOKkE22poZw==,es256,+presence"
      ]);
    };
  };

  virtualisation = {
    containers = {
      enable = true;
      containersConf.settings.engine.detach_keys = "ctrl-q,ctrl-e";
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

