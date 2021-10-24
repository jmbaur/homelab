{ config, pkgs, ... }:

{
  imports =
    [
      ../../config
      ../../pkgs
      ./hardware-configuration.nix
    ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "okra";

  time.timeZone = "America/Los_Angeles";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  custom = {
    ddcci.enable = true;
    git.enable = true;
    gnome.enable = true;
    neovim.enable = true;
    tmux.enable = true;
    vscode.enable = true;
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
    nixopsUnstable
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
    zoom-us
  ];

  programs.adb.enable = true;
  programs.mtr.enable = true;

  services.udev.packages = [ pkgs.yubikey-personalization ];
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };
  virtualisation.libvirtd.enable = true;

  services.openssh.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}
