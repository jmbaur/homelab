{ config, lib, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  hardware.bluetooth.enable = true;
  hardware.enableRedistributableFirmware = true;

  boot.kernelPackages = pkgs.linuxPackages_5_16;
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

  services.xserver = {
    videoDrivers = [ "intel" ];
    deviceSection = ''
      Option "DRI" "2"
      Option "TearFree" "true"
    '';
  };

  custom.cache.enable = false;
  custom.common.enable = true;
  custom.containers.enable = true;
  custom.gui.enable = true;
  custom.jared.enable = true;
  custom.laptop.enable = true;
  custom.sound.enable = true;
  home-manager.users.jared = {
    custom.common.enable = true;
    custom.gui.enable = true;
    custom.laptop.enable = true;
  };

  services.hardware.bolt.enable = true;

  users.users.jared.hashedPassword = "$6$55d7EQl9IIMAuyHm$9CvNhY1gM7hZzaYdmBOugCKa.8cd2I4Myv7iMtzQ13aKDF4Dv8uNn41sOoh8JVjsFGIcjf2tZMb7T3/OgJh2/0";

  services.snapper.configs.home = {
    subvolume = "/home";
    extraConfig = ''
      TIMELINE_CREATE=yes
      TIMELINE_CLEANUP=yes
    '';
  };

  nixpkgs.config.allowUnfree = true;

  services.fwupd.enable = true;

  environment.pathsToLink = [ "/share/zsh" "/share/nix-direnv" ];
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
