{ config, pkgs, ... }:

let
  nixos-hardware = builtins.fetchTarball "https://github.com/nixos/nixos-hardware/archive/master.tar.gz";
in
{
  imports = [
    "${nixos-hardware}/common/pc/ssd"
    "${nixos-hardware}/lenovo/thinkpad/t495"
    ../../custom/vim
    ../../custom/xmonad
    ./hardware-configuration.nix
  ];

  custom = {
    vim.enable = true;
    xmonad.enable = true;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # TLP causing issues with USB ports turning off. Override TLP set from
  # https://github.com/NixOS/nixos-hardware/blob/master/common/pc/laptop/default.nix
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  services.fwupd.enable = true;

  hardware.cpu.amd.updateMicrocode = true;

  hardware.bluetooth.enable = true;

  services.xserver.libinput = {
    enable = true;
    touchpad = {
      accelProfile = "flat";
      tapping = true;
      naturalScrolling = true;
    };
  };

  services.udev.packages = [ pkgs.yubikey-personalization ];
  boot.initrd.luks = {
    gpgSupport = true;
    devices.cryptlvm = {
      allowDiscards = true;
      device = "/dev/disk/by-uuid/957a8112-c937-40b4-a8f9-47c7218a46a1";
      preLVM = true;
      gpgCard = {
        publicKey = ../../lib/pgp_keys.asc;
        encryptedPass = ./disk.key.gpg;
        gracePeriod = 30;
      };
    };
  };

  environment.variables = {
    HISTCONTROL = "ignoredups";
  };

  time.timeZone = "America/Los_Angeles";

  networking.hostName = "beetroot";
  networking.wireless.enable = true;
  networking.wireless.interfaces = [ "wlp1s0" ];

  networking.interfaces.enp3s0f0.useDHCP = true;
  networking.interfaces.enp4s0.useDHCP = true;
  networking.interfaces.wlp1s0.useDHCP = true;

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };


  services.xserver.layout = "us";
  services.xserver.xkbOptions = "ctrl:nocaps";

  services.printing.enable = true;

  sound.enable = true;
  hardware.pulseaudio.enable = true;

  users.users.jared = {
    description = "Jared Baur";
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  environment.systemPackages = with pkgs; [
    curl
    fd
    firefox
    git
    htop
    kitty
    neofetch
    pass
    ripgrep
    tmux
    w3m
    wget
  ];

  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  virtualisation.podman.enable = true;
  virtualisation.libvirtd.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?
}
