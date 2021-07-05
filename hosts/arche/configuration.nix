{ config, pkgs, ... }: {

  imports = [
    "${
      builtins.fetchGit {
        url = "https://github.com/NixOS/nixos-hardware.git";
        rev = "03c60a2db286bcd8ecfac9a8739c50626ca0fd8e";
        ref = "master";
      }
    }/lenovo/thinkpad/x13"
    ../../hardware-configuration.nix
    ../../xorg.nix
    ../../user-profile.nix
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
  boot.extraModulePackages = with pkgs; [ linuxPackages.v4l2loopback ];

  networking.hostName = "arche"; # Define your hostname.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  services.fwupd.enable = true;
  services.udisks2.enable = true;
  services.printing.enable = true;
  services.geoclue2.enable = true;
  services.tailscale.enable = false;

  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    hack-font
    ibm-plex
    dejavu_fonts
    liberation_ttf
  ];

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.bluetooth.enable = true;
  hardware.cpu.amd.updateMicrocode = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    nixfmt
    git
    vim
    nix-prefetch-git
    killall
    lm_sensors
    iputils
    inetutils
    dnsutils
    dig
    tcpdump
    iperf3
    file
    zip
    unzip
  ];
  programs.ssh.startAgent = true;
  environment.binsh = "${pkgs.dash}/bin/dash";

  virtualisation.podman.enable = true;
  virtualisation.podman.dockerCompat = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?
}
