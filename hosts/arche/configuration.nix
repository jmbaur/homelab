{ config, pkgs, ... }:
let
  home-manager = builtins.fetchGit {
    url = "https://github.com/nix-community/home-manager.git";
    rev = "35a24648d155843a4d162de98c17b1afd5db51e4";
    ref = "release-21.05";
  };
in {
  imports = [
    ../../hardware-configuration.nix
    "${
      builtins.fetchGit {
        url = "https://github.com/NixOS/nixos-hardware.git";
        rev = "03c60a2db286bcd8ecfac9a8739c50626ca0fd8e";
        ref = "master";
      }
    }/lenovo/thinkpad/x13"
    (import "${home-manager}/nixos")
    ../../programs/tmux.nix
    ../../programs/git.nix
    ../../programs/psql.nix
    ../../programs/email.nix
    ../../roles/common.nix
    ../../roles/desktop.nix
    ../../roles/code.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.memtest86.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices.cryptlvm = {
    device = "/dev/disk/by-uuid/4217909d-2845-4b4d-b8ba-05a27a2476b8";
    preLVM = true;
    allowDiscards = true;
  };

  networking.hostName = "arche";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Los_Angeles";
  console.useXkbConfig = true;

  services.fwupd.enable = true;
  services.udisks2.enable = true;
  services.printing.enable = true;
  services.geoclue2.enable = true;
  services.tailscale.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    # alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    hack-font
    ibm-plex
    dejavu_fonts
    liberation_ttf
  ];

  sound.enable = true;
  hardware.bluetooth.enable = true;
  hardware.cpu.amd.updateMicrocode = true;

  environment.systemPackages = with pkgs; [
    pulsemixer
    gnupg
    pinentry
    nix-prefetch-git
    file
    zip
    unzip
    curl
    wget
    jq
    htop
    pass
    nvme-cli
    ffmpeg-full
    sshping
    w3m
    xsel
    xclip
    glib
    neofetch
    speedtest-cli
    tree
    pstree
    break-time
  ];

  programs.gnupg = {
    agent = {
      enable = true;
      pinentryFlavor = "tty";
      enableSSHSupport = true;
    };
  };

  users.users.jared = {
    extraGroups = [ "networkmanager" "video" "wireshark" ];
    shell = pkgs.bash;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?
}
