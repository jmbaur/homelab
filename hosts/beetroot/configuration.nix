{ config, lib, pkgs, ... }:
with lib;

{
  imports = [
    ../../config
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
    cleanTmpDir = true;
    extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
    initrd.luks.devices.cryptlvm = { allowDiscards = true; preLVM = true; device = "/dev/disk/by-uuid/951caec2-ca49-4e30-bfbf-0d53e12ee5ca"; };
    kernelPackages = pkgs.linuxPackages_5_14;
    kernelParams = [ "amdgpu.backlight=0" "acpi_backlight=none" ];
    loader = { systemd-boot.enable = true; efi.canTouchEfiVariables = true; };
    tmpOnTmpfs = true;
  };

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "ter-x24b";
    useXkbConfig = mkIf config.services.xserver.enable true;
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

  environment.binsh = "${pkgs.dash}/bin/dash";
  environment.variables = { NNN_TRASH = "1"; };


  nixpkgs.config.allowUnfree = true;

  custom = {
    git.enable = true;
    i3.enable = false;
    sway.enable = true;
    kitty.enable = true;
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
    terminus_font
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
  programs.mtr.enable = true;

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
    # TODO(jared): Currently broken:
    # pass
    # pass-git-helper
    # tree
    acpi
    age
    alacritty
    atop
    awscli2
    bat
    bc
    bind
    bitwarden
    curl
    direnv
    discord
    dmidecode
    dnsutils
    drawio
    dust
    exa
    fd
    fdroidcl
    ffmpeg
    ffmpeg-full
    file
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
    htop
    imv
    iperf3
    iputils
    jq
    keybase
    killall
    libreoffice
    librespeed-cli
    lm_sensors
    mob
    mosh
    mpv
    nix-direnv
    nix-tree
    nixopsUnstable
    nixos-generators
    nmap
    nnn
    nushell
    nvme-cli
    p
    pa-switch
    pavucontrol
    pciutils
    pfetch
    picocom
    pinentry-gnome
    plan9port
    procs
    pwgen
    renameutils
    ripgrep
    rtorrent
    sd
    signal-desktop
    sl
    speedtest-cli
    spotify
    stow
    tailscale
    tcpdump
    tea
    tealdeer
    tig
    tmux
    tokei
    traceroute
    trash-cli
    unzip
    usbutils
    w3m
    wget
    wireshark
    xclip
    xclip
    xcolor
    xdg-user-dirs
    xdg-utils
    xsel
    xsv
    ydiff
    yq
    yubikey-personalization
    zathura
    zip
    zoom-us
    zoxide
  ] ++ (
    if config.custom.sway.enable then
      let
        start-recording = writeShellScriptBin "start-recording" ''
          LABEL="WfRecorder"
          sudo modprobe v4l2loopback exclusive_caps=1 card_label=$LABEL
          DEVICE=$(${pkgs.v4l-utils}/bin/v4l2-ctl --list-devices | grep $LABEL -A1 | tail -n1 | sed 's/\s//')
          ${pkgs.wf-recorder}/bin/wf-recorder --muxer=v4l2 --codec=rawvideo --file=$DEVICE -x yuv420p
        '';
        stop-recording = writeShellScriptBin "stop-recording" ''
          sudo modprobe --remove v4l2loopback
        '';
        chromium-wayland = (chromium.override
          {
            commandLineArgs = [ "--enable-features=UseOzonePlatform" "--ozone-platform=wayland" ];
          });
        obs-studio-wayland = (wrapOBS { plugins = with obs-studio-plugins; [ wlrobs ]; });
        slack-wayland = (symlinkJoin {
          name = "slack";
          paths = [ pkgs.slack ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/slack \
              --add-flags "--ozone-platform=wayland" \
              --add-flags "--enable-features=WebRTCPipeWireCapturer" \
              --add-flags "--enable-features=UseOzonePlatform"
          '';
        });
      in
      [
        chromium-wayland
        obs-studio-wayland
        pkgs.element-desktop-wayland
        pkgs.firefox-wayland
        pkgs.thunderbird-wayland
        slack-wayland
        start-recording
        stop-recording
      ] else
      with pkgs; [
        chromium
        element-desktop
        firefox
        obs-studio
        slack
        thunderbird
      ]
  );

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
    shell = pkgs.bash;
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
