{ config, lib, pkgs, ... }:
with lib;
{
  imports = [
    ../../config
    ../../lib/common.nix
    ../../pkgs
    ./hardware-configuration.nix
  ];

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
  environment.pathsToLink = [
    "/share/nix-direnv"
  ];
  boot = {
    binfmt.emulatedSystems = [ "aarch64-linux" ]; # allow building for RPI4
    extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
    initrd.luks.devices.cryptlvm = { allowDiscards = true; preLVM = true; device = "/dev/disk/by-uuid/951caec2-ca49-4e30-bfbf-0d53e12ee5ca"; };
    kernelPackages = pkgs.linuxPackages_5_14;
    kernelParams = [ "amdgpu.backlight=0" "acpi_backlight=none" ];
    loader = { systemd-boot.enable = true; efi.canTouchEfiVariables = true; };
  };

  security.tpm2.enable = true;

  hardware = {
    bluetooth.enable = true;
    cpu.amd.updateMicrocode = true;
    enableRedistributableFirmware = true;
  };

  networking.hostName = "beetroot";
  networking.networkmanager.enable = true;
  time.timeZone = "America/Los_Angeles";

  environment.variables = { NNN_TRASH = "1"; };

  nixpkgs.config.allowUnfree = true;

  custom = {
    git.enable = true;
    i3.enable = false;
    sway.enable = true;
    neovim.enable = true;
    pipewire.enable = true;
    tmux.enable = true;
    vscode.enable = false;
  };

  fonts.fonts = with pkgs; [
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

  services.xserver.libinput = mkIf config.services.xserver.enable {
    enable = true;
    touchpad = {
      accelProfile = "flat";
      tapping = true;
      naturalScrolling = true;
    };
  };

  programs.wireshark.enable = true;
  programs.adb.enable = true;

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
    buildah
    chromium
    direnv
    discord
    drawio
    dust
    element-desktop-wayland
    exa
    fd
    fdroidcl
    ffmpeg
    ffmpeg-full
    firefox-wayland
    fzf
    geteltorito
    gh
    gimp
    git
    git-get
    gnumake
    gnupg
    gosee
    gotop
    grex
    gron
    htmlq
    imv
    jq
    keybase
    libreoffice
    librespeed-cli
    mob
    mosh
    mpv
    nix-direnv
    nix-tree
    nixopsUnstable
    nixos-generators
    nnn
    nushell
    nvme-cli
    p
    pa-switch
    pass
    pass-git-helper
    pavucontrol
    picocom
    pinentry-gnome
    plan9port
    pwgen
    renameutils
    ripgrep
    rtorrent
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
    thunderbird-wayland
    tig
    tokei
    trash-cli
    unzip
    usbutils
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
  system.userActivationScripts.nix-direnv.text =
    let
      direnvrc = pkgs.writeTextFile {
        name = "direnvrc";
        text = ''
          source ${pkgs.nix-direnv}/share/nix-direnv/direnvrc
        '';
      };
    in
    ''
      ln -sf ${direnvrc} ''${HOME}/.direnvrc
    '';

  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = false;
    promptInit = ''
      PS1="%F{cyan}%n@%m%f:%F{green}%c%f %% "
    '';
    # Prevent zsh-newuser-install from showing
    shellInit = ''
      export DISABLE_AUTO_TITLE=true
      zsh-newuser-install() { :; }
      bindkey -e
      bindkey \^U backward-kill-line
    '';
    interactiveShellInit = ''
      eval "$(${pkgs.direnv}/bin/direnv hook zsh)"
    '';
  };

  # Yubikey GPG and SSH support
  services.udev.packages = [ pkgs.yubikey-personalization ];
  programs = {
    ssh.startAgent = false;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryFlavor = "gnome3";
    };
  };

  users.users.jared = {
    description = "Jared Baur";
    extraGroups = [ "adbusers" "networkmanager" "wheel" "wireshark" ];
    isNormalUser = true;
    shell = pkgs.zsh;
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
