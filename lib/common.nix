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

  environment.systemPackages = with pkgs; [
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
    pass-git-helper
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
    tea
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
  ];

  programs.bash = {
    vteIntegration = true;
    undistractMe.enable = true;
  };

  programs.zsh = {
    enable = true;
    vteIntegration = true;
  };

  # Yubikey GPG and SSH support
  services.udev.packages = [ pkgs.yubikey-personalization ];
  programs = {
    ssh.startAgent = false;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  security.sudo.wheelNeedsPassword = false;

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
