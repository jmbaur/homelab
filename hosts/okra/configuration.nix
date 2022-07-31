{ config, lib, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  boot.kernelPackages = pkgs.linuxPackages_5_18;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "America/Los_Angeles";

  services.resolved.enable = true;
  networking = {
    useDHCP = false;
    hostName = "okra";
    useNetworkd = true;
  };
  systemd.services."systemd-networkd".environment.SYSTEMD_LOG_LEVEL = "debug";
  systemd.network = {
    networks.wired = {
      name = "en*";
      DHCP = "yes";
      networkConfig.IPv6PrivacyExtensions = true;
      dhcpV4Config.ClientIdentifier = "mac";
    };
  };

  custom = {
    common.enable = true;
    dev.enable = true;
    gui.enable = true;
  };

  users.users.jared = {
    isNormalUser = true;
    description = "Jared Baur";
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
  };
  home-manager.users.jared = { config, globalConfig, ... }: {
    programs.git = {
      userEmail = "jaredbaur@fastmail.com";
      userName = globalConfig.users.users.jared.description;
    };
    xdg.configFile."gobar/gobar.yaml".source = (pkgs.formats.yaml { }).generate "gobar.yaml" {
      modules = [
        { module = "network"; pattern = "(en|wl|wg)+"; }
        { module = "memory"; }
        { module = "datetime"; }
      ];
    };
    home.packages = with pkgs; [
      age-plugin-yubikey
      discord-webapp
      firefox-wayland
      freerdp
      google-chrome
      outlook-webapp
      signal-desktop
      slack-webapp
      spotify-webapp
      teams-webapp
    ];
  };

  nixpkgs.config.allowUnfree = true;

  services.fwupd.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}
