{ config, pkgs, ... }:
let
  fdroidcl = import ../programs/fdroidcl { };
  gosee = import (builtins.fetchTarball "https://gitea.jmbaur.com/jmbaur/gosee/archive/main.tar.gz") { };
  htmlq = import ../programs/htmlq { };
  proj = import ../programs/proj { };
in
{
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
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  console.useXkbConfig = true;

  networking.networkmanager.enable = true;

  environment.binsh = "${pkgs.dash}/bin/dash";
  environment.variables = {
    EDITOR = "nvim";
    NNN_TRASH = "1";
  };

  environment.systemPackages = with pkgs; [
    acpi
    atop
    awscli2
    bat
    bc
    bind
    cmus
    curl
    direnv
    dmidecode
    dnsutils
    dust
    exa
    fd
    fdroidcl
    ffmpeg
    file
    fzf
    geteltorito
    gh
    git
    gnupg
    gosee
    gotop
    grex
    gron
    htmlq
    htop
    iperf3
    iputils
    jq
    keybase
    killall
    libnotify
    lm_sensors
    mosh
    neofetch
    nix-direnv
    nixops
    nmap
    nnn
    nushell
    nvme-cli
    pass
    pass-git-helper
    pciutils
    picocom
    procs
    proj
    pwgen
    renameutils
    ripgrep
    rtorrent
    sd
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
    shellAliases = { grep = "grep --color=auto"; };
    enableLsColors = true;
    enableCompletion = true;
    shellInit = ''
      export HISTCONTROL=ignoreboth:erasedups
    '';
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
