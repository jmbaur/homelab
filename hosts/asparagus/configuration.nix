{ config, lib, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  hardware.bluetooth.enable = true;
  hardware.enableRedistributableFirmware = true;

  boot.kernelPackages = pkgs.linuxPackages_5_17;
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  boot.loader.systemd-boot = {
    enable = true;
    memtest86.enable = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "asparagus";
  networking.useDHCP = lib.mkForce false;
  networking.networkmanager.enable = true;
  networking.interfaces.enp3s0f0.useDHCP = false;
  networking.interfaces.wlp2s0.useDHCP = false;

  time.timeZone = "America/Los_Angeles";

  custom.cache.enable = false;
  custom.common.enable = true;
  custom.containers.enable = true;
  custom.deploy.enable = true;
  custom.desktop.enable = true;
  custom.gui.enable = true;
  custom.jared.enable = true;
  custom.sound.enable = true;
  home-manager.users.jared = {
    custom.common.enable = true;
    custom.gui.enable = true;
  };

  users.users.jared.hashedPassword = "$6$01ZXrxetiKaCW6Yx$RfI18qNyAYd9lU91wBNA9p0XREabwV4cv8DFqGH96SZnLJYmbGUTjNyqrVUgJorBn5RQzwwI4Ws3xMMU.fvYk/";

  services.snapper.configs.home = {
    subvolume = "/home";
    extraConfig = ''
      TIMELINE_CREATE=yes
      TIMELINE_CLEANUP=yes
    '';
  };

  nixpkgs.config.allowUnfree = true;
  services.power-profiles-daemon.enable = true;
  services.fwupd.enable = true;
  programs.nix-ld.enable = true;
  programs.mosh.enable = true;

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
