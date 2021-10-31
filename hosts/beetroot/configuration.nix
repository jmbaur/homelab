{ config, pkgs, ... }:
let

  nixos-hardware = builtins.fetchTarball {
    url = "https://github.com/nixos/nixos-hardware/archive/3aabf78bfcae62f5f99474f2ebbbe418f1c6e54f.tar.gz";
    sha256 = "10g240brgjz7qi20adwajxwqrqb5zxc79ii1mc20fasgqlf2a8sx";
  };

in
{
  imports = [
    "${nixos-hardware}/common/pc/ssd"
    "${nixos-hardware}/lenovo/thinkpad/t495"
    ../../config
    ../../pkgs
    ./hardware-configuration.nix
  ];

  security.tpm2.enable = true;

  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  services.fwupd.enable = true;

  services.avahi.enable = true;
  services.avahi.nssmdns = true;

  hardware.cpu.amd.updateMicrocode = true;

  hardware.bluetooth.enable = true;

  nixpkgs.config.allowUnfree = true;

  custom = {
    awesome.enable = true;
    awesome.laptop = true;
    git.enable = true;
    kitty.enable = true;
    neovim.enable = true;
    pipewire.enable = true;
    tmux.enable = true;
    vscode.enable = true;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices =
    let
      uuid = "8d642c40-ad46-407f-ba23-07be974c033f";
    in
    {
      "${uuid}" = {
        allowDiscards = true;
        device = "/dev/disk/by-uuid/${uuid}";
        preLVM = true;
      };
    };

  networking.hostName = "beetroot";
  networking.networkmanager.enable = true;

  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  time.timeZone = "America/Los_Angeles";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  users.users.jared = {
    description = "Jared Baur";
    isNormalUser = true;
    extraGroups = [ "video" "wheel" "networkmanager" "adbusers" ];
  };

  environment.variables.HISTCONTROL = "ignoredups";

  environment.systemPackages = with pkgs; [
    age
    bat
    bitwarden
    chromium
    element-desktop
    fd
    fdroidcl
    file
    firefox
    gimp
    google-chrome
    gosee
    htmlq
    htop
    jq
    libreoffice
    mob
    nix-tree
    nixos-generators
    p
    pa-switch
    ripgrep
    signal-desktop
    slack
    spotify
    thunderbird
    tokei
    w3m
    wget
    zip
    zoom-us
  ];

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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
