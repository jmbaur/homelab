{ config, lib, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  boot.kernelPackages = pkgs.linuxPackages_5_18;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "America/Los_Angeles";

  services.mullvad-vpn.enable = true;
  services.resolved.enable = true;

  networking = {
    useDHCP = lib.mkForce false;
    hostName = "okra";
    useNetworkd = true;
    wireless.enable = true;
  };
  systemd.network = {
    wait-online.anyInterface = true;
    networks.wireless = {
      name = "wl*";
      DHCP = "yes";
      networkConfig.IPv6PrivacyExtensions = true;
      dhcpV4Config.ClientIdentifier = "mac";
    };
  };

  custom = {
    common.enable = true;
    gui.enable = true;
    deployee = {
      enable = true;
      authorizedKeyFiles = [
        (import ../../data/jmbaur-ssh-keys.nix)
        ../../data/deployer-ssh-keys.txt
      ];
    };
    # NOTE: This can be true if wireless interfaces can be configured in the
    # initrd.
    remoteBoot.enable = false;
  };

  documentation.enable = false;

  users.users.jared = {
    isNormalUser = true;
    description = "Jared Baur";
    extraGroups = [ "wheel" ];
  };
  home-manager.users.jared = { config, ... }: {
    home.packages = with pkgs; [
      firefox-wayland
      google-chrome
      mullvad-vpn
      spotify-webapp
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
