{ config, lib, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  boot.kernelPackages = pkgs.linuxPackages_5_17;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  nixpkgs.config.allowUnfree = true;

  networking = {
    useDHCP = false;
    useNetworkd = true;
    hostName = "okra";
    wireless.iwd.enable = true;
  };

  systemd.network = {
    networks = {
      wired = {
        matchConfig.Name = "en*";
        networkConfig = {
          DHCP = "yes";
          IPv6PrivacyExtensions = true;
        };
        dhcpV4Config = {
          RouteMetric = 10;
          UseDomains = "yes";
        };
      };

      wireless = {
        matchConfig.Name = "wl*";
        networkConfig = {
          DHCP = "yes";
          IPv6PrivacyExtensions = true;
        };
        dhcpV4Config = {
          RouteMetric = 20;
          UseDomains = "yes";
        };
      };
    };
  };

  time.timeZone = "America/Los_Angeles";

  custom.common.enable = true;
  custom.deploy.enable = true;
  custom.gui.enable = true;
  custom.jared.enable = true;
  custom.sound.enable = true;

  services.fwupd.enable = true;

  environment.systemPackages = with pkgs; [ firefox chromium ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}
