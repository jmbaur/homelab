{ config, lib, pkgs, ... }:
with lib;

let

  nixos-hardware = builtins.fetchTarball {
    url = "https://github.com/nixos/nixos-hardware/archive/518b9c2159e7d4b7696ee18b8828f9086012923b.tar.gz";
    sha256 = "02ybg89zj8x3i5xd70rysizbzx8d8bijml7l62n32i991244rf4b";
  };

in
{
  imports = [
    "${nixos-hardware}/common/pc/ssd"
    "${nixos-hardware}/common/cpu/amd"
    "${nixos-hardware}/common/gpu/amd"
    "${nixos-hardware}/common/pc/laptop/acpi_call.nix"
    "${nixos-hardware}/lenovo/thinkpad"
    ../../config
    ../../pkgs
    ./hardware-configuration.nix
  ];

  boot.kernelParams = [ "amdgpu.backlight=0" "acpi_backlight=none" ];

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
    kernelPackages = pkgs.linuxPackages_5_14;
    cleanTmpDir = true;
    tmpOnTmpfs = true;
    binfmt.emulatedSystems = [ "aarch64-linux" ]; # allow building for RPI4
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    initrd.luks.devices.cryptlvm = {
      allowDiscards = true;
      preLVM = true;
      device = "/dev/disk/by-uuid/951caec2-ca49-4e30-bfbf-0d53e12ee5ca";
    };
  };

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
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
    hack-font
    inconsolata
    liberation_ttf
    noto-fonts
    noto-fonts-emoji
    source-code-pro
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
    acpi
    age
    atop
    awscli2
    bat
    bc
    bind
    curl
    direnv
    discord
    dmidecode
    dnsutils
    drawio
    dunst
    dust
    exa
    fd
    fdroidcl
    ffmpeg
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
    lm_sensors
    mob
    mosh
    nix-direnv
    nix-tree
    nixops
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
    procs
    pwgen
    renameutils
    ripgrep
    rtorrent
    sd
    signal-desktop
    sl
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
    bitwarden
    unzip
    usbutils
    w3m
    wget
    wireshark
    xclip
    xclip
    xcolor
    xdg-user-dirs
    xsel
    xsv
    ydiff
    yq
    yubikey-personalization
    zathura
    zip
    zoom-us
    zoxide
    # TODO(jared): Currently broken:
    # tree
    # pass
    # pass-git-helper
  ] ++ (
    with pkgs; if config.custom.sway.enable then [
      (brave.override
        {
          commandLineArgs = [ "--enable-features=UseOzonePlatform" "--ozone-platform=wayland" ];
        })
      (chromium.override
        {
          commandLineArgs = [ "--enable-features=UseOzonePlatform" "--ozone-platform=wayland" ];
        })
      element-desktop-wayland
      firefox-wayland
      (symlinkJoin {
        name = "slack";
        paths = [ pkgs.slack ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/slack \
          --add-flags "--enable-features=UseOzonePlatform" \
          --add-flags "--ozone-platform=wayland" \
          --add-flags "--enable-features=WebRTCPipeWireCapturer"
        '';
      })
      thunderbird-wayland
    ] else [
      brave
      chromium
      element-desktop
      firefox
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

  environment.variables.DISABLE_AUTO_TITLE = "true";
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
    openssh.authorizedKeys.keys = [ "${builtins.readFile ./yubikeySshKey.txt}" ];
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
