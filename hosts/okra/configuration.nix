{ config, lib, pkgs, ... }: {
  imports = [
    ./networking.nix
    ./hardware-configuration.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_5_17;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "America/Los_Angeles";

  custom.common.enable = true;
  custom.deploy.enable = true;
  custom.gui.enable = true;
  custom.jared.enable = true;
  custom.sound.enable = true;
  home-manager.users.jared.custom.gui.enable = true;

  nixpkgs.config.allowUnfree = true;

  services.fwupd.enable = true;

  environment.systemPackages = with pkgs; [ mullvad-vpn ];

  environment.etc."xdg/gobar/gobar.yaml".text = lib.generators.toYAML { } {
    modules = [
      { module = "network"; interface = "wlan0"; }
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
