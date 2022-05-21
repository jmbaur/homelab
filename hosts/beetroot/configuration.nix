{ config, lib, pkgs, ... }: {
  imports = [ ./networking.nix ./hardware-configuration.nix ];

  hardware.enableRedistributableFirmware = true;

  # TODO(jared): https://github.com/NixOS/nixpkgs/issues/170573
  hardware.bluetooth.enable = true;
  systemd.tmpfiles.rules = [
    "d /var/lib/bluetooth 700 root root - -"
  ];
  systemd.targets."bluetooth".after = [ "systemd-tmpfiles-setup.service" ];

  boot.kernelParams = [ "acpi_backlight=native" ];
  boot.kernelPackages = pkgs.linuxPackages_5_17;
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.systemd.enable = true;

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age = { generateKey = true; keyFile = "/etc/age/key"; };
    secrets.wg0 = {
      mode = "0640";
      owner = config.users.users.root.name;
      group = config.users.groups.systemd-network.name;
    };
  };

  custom.cache.enable = false;
  custom.common.enable = true;
  custom.containers.enable = true;
  custom.gui.enable = true;
  custom.jared.enable = true;
  custom.sound.enable = true;
  home-manager.users.jared = {
    custom.common.enable = true;
    custom.gui.enable = true;
    custom.gui.laptop = true;
  };

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
  services.fprintd.enable = true;
  security.pam.services.sudo.fprintAuth = false;
  programs.nix-ld.enable = true;

  environment.pathsToLink = [ "/share/nix-direnv" ];
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
  '';

  environment.etc."xdg/gobar/gobar.yaml".text = lib.generators.toYAML { } {
    modules = [
      { module = "battery"; name = "BAT0"; }
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
