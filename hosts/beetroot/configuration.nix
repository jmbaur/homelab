{ config, lib, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  hardware.bluetooth.enable = true;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;

  boot.kernelPackages = pkgs.linuxPackages_5_15;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.useDHCP = false;
  networking.hostName = "beetroot";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Los_Angeles";

  custom.common.enable = true;
  custom.desktop.enable = true;
  custom.git.enable = true;
  custom.neovim.enable = true;
  custom.tmux.enable = true;

  users.users.jared = {
    isNormalUser = true;
    initialPassword = "helloworld";
    extraGroups = [
      "adbusers"
      "dialout"
      "libvirtd"
      "networkmanager"
      "wheel"
      "wireshark"
    ];
  };

  environment.variables.NNN_TRASH = "1";

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # fido2luks
    # start-recording
    # stop-recording
    age
    awscli2
    bat
    bitwarden
    buildah
    chromium
    direnv
    dust
    element-desktop-wayland
    exa
    fd
    fdroidcl
    ffmpeg-full
    firefox-wayland
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
    librespeed-cli
    mob
    mosh
    mpv
    nix-direnv
    nix-prefetch-docker
    nix-tree
    nixos-generators
    nnn
    nushell
    nvme-cli
    openssl
    p
    pass
    pass-git-helper
    patchelf
    picocom
    plan9port
    pstree
    pwgen
    renameutils
    ripgrep
    rtorrent
    scrot
    sd
    signal-desktop
    skopeo
    sl
    speedtest-cli
    spotify
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
    ventoy-bin
    vim
    wine64
    xdg-user-dirs
    xdg-utils
    xsv
    ydiff
    yq
    yubikey-manager
    yubikey-personalization
    zip
    zoxide
    zsh
  ];

  programs.ssh.startAgent = true;
  programs.mtr.enable = true;
  programs.wireshark.enable = true;
  programs.adb.enable = true;

  xdg.mime.defaultApplications = {
    "application/pdf" = "firefox.desktop";
    "image/png" = "imv.desktop";
  };

  programs.bash = {
    vteIntegration = true;
    shellAliases = { grep = "grep --color=auto"; };
    enableLsColors = true;
    enableCompletion = true;
    interactiveShellInit = ''
      eval "$(${pkgs.direnv}/bin/direnv hook bash)"
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
  services.fwupd.enable = true;
  services.hardware.bolt.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  services.printing.enable = true;

  networking.firewall.enable = false;
  networking.nftables = {
    enable = true;
    rulesetFile = ./desktop.nft;
  };

  virtualisation = {
    containers = {
      enable = true;
      containersConf.settings.engine.detach_keys = "ctrl-q,ctrl-e";
    };
    podman.enable = true;
    libvirtd.enable = true;
  };


  nix.extraOptions = ''
    experimental-features = nix-command flakes
    keep-outputs = true
    keep-derivations = true
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
