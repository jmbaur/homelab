{ config, lib, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  hardware.bluetooth.enable = true;
  hardware.enableRedistributableFirmware = true;

  boot.kernelPackages = pkgs.linuxPackages_5_15;
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  boot.loader.systemd-boot = {
    enable = true;
    memtest86.enable = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "beetroot";
  networking.useDHCP = lib.mkForce false;
  networking.networkmanager.enable = true;

  time.timeZone = "America/Los_Angeles";

  custom.cache.enable = false;
  custom.common.enable = true;
  custom.sound.enable = true;
  custom.containers.enable = true;

  services.xserver = {
    enable = true;
    libinput = {
      enable = true;
      touchpad = {
        tapping = true;
        naturalScrolling = true;
        disableWhileTyping = true;
        accelProfile = "flat";
      };
    };
    displayManager.lightdm.enable = true;
    windowManager.i3.enable = true;
    videoDrivers = [ "intel" ];
    deviceSection = ''
      Option "TearFree" "true"
    '';
  };

  programs.adb.enable = true;
  programs.seahorse.enable = true;
  programs.wireshark.enable = true;
  services.autorandr.enable = true;
  services.avahi = { enable = true; nssmdns = true; };
  services.dbus.packages = [ pkgs.gcr ];
  services.geoclue2.enable = true;
  services.hardware.bolt.enable = true;
  services.pcscd.enable = false;
  services.power-profiles-daemon.enable = true;
  services.printing.enable = true;
  services.udev.packages = [ pkgs.yubikey-personalization ];
  services.udisks2.enable = true;
  services.upower.enable = true;

  fonts.fonts = [ pkgs.hack-font ];

  users = {
    users.jared = {
      isNormalUser = true;
      hashedPassword = "$6$01ZXrxetiKaCW6Yx$RfI18qNyAYd9lU91wBNA9p0XREabwV4cv8DFqGH96SZnLJYmbGUTjNyqrVUgJorBn5RQzwwI4Ws3xMMU.fvYk/";
      description = "Jared Baur";
      extraGroups = [
        "adbusers"
        "dialout"
        "networkmanager"
        "wheel"
        "wireshark"
      ];
    };
  };

  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    users.jared = import ../../homes/jared;
  };

  services.snapper.configs.home = {
    subvolume = "/home";
    extraConfig = ''
      TIMELINE_CREATE=yes
      TIMELINE_CLEANUP=yes
    '';
  };

  nixpkgs.config.allowUnfree = true;

  programs.mtr.enable = true;
  programs.ssh.startAgent = true;

  services.fwupd.enable = true;

  # for nix-direnv
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}
