{ config, pkgs, ... }:

{
  imports =
    [
      ../../config
      ../../pkgs
      ./hardware-configuration.nix
    ];

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [ "i2c-dev" ];
  services.udev.extraRules = ''KERNEL=="i2c-[0-9]*", GROUP+="users"'';

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "okra";
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  custom = {
    git.enable = true;
    kitty.enable = true;
    neovim.enable = true;
    tmux.enable = true;
    vscode.enable = true;
  };

  services.xserver = {
    enable = true;
    layout = "us";
    xkbOptions = "ctrl:nocaps";
    desktopManager.xfce.enable = true;
    deviceSection = ''
      Option "TearFree" "true"
    '';
  };


  boot.initrd.luks.devices =
    let
      uuid = "b9b68eee-c3b9-48f0-9b8c-8c31fce4f185";
    in
    {
      "${uuid}" = {
        allowDiscards = true;
        preLVM = true;
        device = "/dev/disk/by-uuid/${uuid}";
      };
    };

  nixpkgs.config.allowUnfree = true;

  hardware.cpu.amd.updateMicrocode = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jared = {
    description = "Jared Baur";
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "adbusers" ];
  };

  environment.variables.HISTCONTROL = "ignoredups";

  environment.systemPackages = with pkgs; [
    age
    bat
    bitwarden
    element-desktop
    fd
    fdroidcl
    firefox
    gimp
    google-chrome
    gosee
    htmlq
    htop
    jq
    libreoffice
    mob
    nushell
    pa-switch
    proj
    ripgrep
    signal-desktop
    slack
    spotify
    thunderbird
    tig
    tokei
    vim
    w3m
    wget
    xfce.xfce4-battery-plugin
    xfce.xfce4-clipman-plugin
    zoom-us
  ];

  programs.slock.enable = true;
  programs.adb.enable = true;
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };
  virtualisation.libvirtd.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}
