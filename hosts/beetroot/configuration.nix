{ config, lib, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  hardware.enableRedistributableFirmware = true;

  # TODO(jared): https://github.com/NixOS/nixpkgs/issues/170573
  hardware.bluetooth.enable = true;
  # systemd.tmpfiles.rules = [
  #   "d /var/lib/bluetooth 700 root root - -"
  # ];
  # systemd.targets."bluetooth".after = [ "systemd-tmpfiles-setup.service" ];

  boot.kernelParams = [ "acpi_backlight=native" ];
  boot.kernelPackages = pkgs.linuxPackages_5_17;
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.systemd.enable = true;

  # Don't set timezone declaratively since this is a laptop.
  networking = {
    useDHCP = lib.mkForce false;
    hostName = "beetroot";
    networkmanager.enable = true;
  };

  sops = {
    # defaultSopsFile = ./secrets.yaml;
    age = { generateKey = true; keyFile = "/etc/age/key"; };
  };

  users.users.jared = {
    isNormalUser = true;
    description = "Jared Baur";
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "dialout" "networkmanager" "i2c" "adbusers" ];
  };

  custom = {
    common.enable = true;
    dev.enable = true;
    gui = {
      enable = true;
      backend = "wayland";
    };
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

  home-manager.users.jared = {
    home.packages = with pkgs; [
      bitwarden
      chromium
      element-desktop-wayland
      firefox-wayland
      signal-desktop
      spotify
    ];
    programs.gpg.publicKeys = [{
      source = import ../../data/jmbaur-pgp-keys.nix;
      trust = 5;
    }];
    programs.git = {
      userEmail = "jaredbaur@fastmail.com";
      userName = config.users.users.jared.description;
      signing = {
        key = "7EB08143";
        signByDefault = true;
      };
    };
    xdg.configFile."gobar/gobar.yaml".text = lib.generators.toYAML { } {
      modules = [
        { module = "battery"; index = 0; }
        { module = "network"; pattern = "(en|wl)+"; }
        { module = "datetime"; format = "2006-01-02 15:04:05"; }
      ];
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}
