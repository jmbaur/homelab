{ config, lib, pkgs, ... }: {
  imports = [
    ./networking.nix
    ./hardware-configuration.nix
  ];

  hardware.bluetooth.enable = true;
  hardware.enableRedistributableFirmware = true;

  boot.kernelPackages = pkgs.linuxPackages_5_17;

  boot.initrd.kernelModules = [ "amdgpu" ];
  # boot.kernelParams = [ "console=ttyS1,115200n8" ];
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  boot.loader.systemd-boot = {
    enable = true;
    memtest86.enable = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "America/Los_Angeles";

  custom = {
    cache.enable = false;
    common.enable = true;
    containers.enable = true;
    deployee.enable = true;
    deployer.enable = true;
    gui.enable = true;
    jared = {
      enable = true;
      includeHomeManager = true;
    };
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

  environment.etc."xdg/gobar/gobar.yaml".text = lib.generators.toYAML { } {
    modules = [
      { module = "network"; interface = config.systemd.network.networks.enp4s0.matchConfig.Name; }
      { module = "datetime"; format = "2006-01-02 15:04:05"; }
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}
