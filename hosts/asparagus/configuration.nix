{ config, lib, pkgs, ... }: {
  imports = [
    ./networking.nix
    ./hardware-configuration.nix
  ];

  hardware.bluetooth.enable = true;
  hardware.enableRedistributableFirmware = true;

  boot.kernelPackages = pkgs.linuxPackages_5_17;

  boot.kernelParams = [ "console=ttyS1,115200n8" ];
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  boot.loader.systemd-boot = {
    enable = true;
    memtest86.enable = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "America/Los_Angeles";

  custom.cache.enable = false;
  custom.common.enable = true;
  custom.containers.enable = true;
  custom.deploy.enable = true;
  custom.gui = { enable = true; desktop = true; };
  custom.jared.enable = true;
  custom.sound.enable = true;
  home-manager.users.jared = {
    custom.common.enable = true;
    custom.gui.enable = true;
  };

  services.snapper.configs = {
    home = {
      subvolume = "/home";
      extraConfig = ''
        TIMELINE_CREATE=yes
        TIMELINE_CLEANUP=yes
      '';
    };
    steam = {
      subvolume = "/big/steam";
      extraConfig = ''
        TIMELINE_CREATE=yes
        TIMELINE_CLEANUP=yes
      '';
    };
  };

  environment.systemPackages = [ pkgs.radeontop ];

  nixpkgs.config.allowUnfree = true;
  services.power-profiles-daemon.enable = true;
  services.fwupd.enable = true;
  programs.nix-ld.enable = true;
  programs.mosh.enable = true;
  programs.steam.enable = true;

  environment.pathsToLink = [ "/share/nix-direnv" ];
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
