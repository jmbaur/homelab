{ config, lib, pkgs, ... }:

with lib;

let
  unstable = pkgs.callPackage (builtins.fetchTarball "https://github.com/nixos/nixpkgs/archive/master.tar.gz") { };
in

{
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
    cleanTmpDir = true;
    tmpOnTmpfs = true;
    # binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = mkIf config.services.xserver.enable true;
  };

  networking.networkmanager.enable = true;

  environment.binsh = "${pkgs.dash}/bin/dash";
  environment.variables = { NNN_TRASH = "1"; };

  environment.systemPackages = with pkgs; [
    acpi
    age
    atop
    awscli2
    bat
    bc
    bind
    brave
    brightnessctl
    chromium
    cmus
    curl
    direnv
    dmidecode
    dnsutils
    dunst
    dust
    element-desktop
    exa
    fd
    fdroidcl
    ffmpeg
    file
    firefox
    fzf
    geteltorito
    gh
    gimp
    git
    gnupg
    google-chrome
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
    libnotify
    libreoffice
    lm_sensors
    mob
    mosh
    neofetch
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
    pass
    pass-git-helper
    pavucontrol
    pciutils
    picocom
    pinentry-gnome
    procs
    proj
    pwgen
    renameutils
    ripgrep
    rtorrent
    scrot
    sd
    signal-desktop
    sl
    slack
    spotify
    stow
    tailscale
    tcpdump
    tea
    tealdeer
    thunderbird
    tig
    tmux
    tokei
    traceroute
    trash-cli
    tree
    unzip
    usbutils
    w3m
    wget
    wireshark
    xclip
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
  ] ++ [
    unstable.bitwarden # TODO(jared): just a workaround until 21.11
  ];

  programs.wireshark.enable = true;
  programs.adb.enable = true;
  programs.mtr.enable = true;

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
    ohMyZsh = {
      enable = true;
      theme = "sunaku";
      plugins = [ "git" ];
    };
    syntaxHighlighting.enable = false;
    # Prevent zsh-newuser-install from showing
    shellInit = ''
      export DISABLE_AUTO_TITLE=true
      zsh-newuser-install() { :; }
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

}
