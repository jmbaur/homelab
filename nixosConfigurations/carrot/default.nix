{ config, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];
  hardware.bluetooth.enable = true;

  zramSwap.enable = true;

  boot = {
    initrd = {
      systemd.enable = true;
      luks.devices."cryptroot".crypttabExtraOpts = [ "fido2-device=auto" ];
    };
    kernelPackages = pkgs.linuxPackages_6_0;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  time.timeZone = "America/Los_Angeles";

  networking = {
    useDHCP = false;
    hostName = "carrot";
    useNetworkd = true;
    wireless.enable = true;
  };
  systemd.network = {
    wait-online.anyInterface = true;
    networks = {
      wireless = {
        name = "wl*";
        DHCP = "yes";
        dhcpV4Config.RouteMetric = config.systemd.network.networks.wired.dhcpV4Config.RouteMetric * 2;
        ipv6AcceptRAConfig.RouteMetric = config.systemd.network.networks.wired.ipv6AcceptRAConfig.RouteMetric * 2;
        networkConfig.IPv6PrivacyExtensions = "kernel";
      };
      wired = {
        name = "en*";
        DHCP = "yes";
        dhcpV4Config.RouteMetric = 1024;
        ipv6AcceptRAConfig.RouteMetric = 1024;
        networkConfig.IPv6PrivacyExtensions = "kernel";
      };
    };
  };
  services.resolved.enable = true;

  custom = {
    common.enable = true;
    dev.enable = true;
    gui.enable = true;
    gui.variant = "sway";
    laptop.enable = true;
    users.jared.enable = true;
    remoteBuilders.aarch64builder.enable = true;
  };


  nixpkgs.config.allowUnfree = true;

  services.fwupd.enable = true;

  security.pam.u2f = {
    enable = true;
    cue = true;
    origin = "pam://homelab";
    authFile = config.sops.secrets.pam_u2f_authfile.path;
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets.pam_u2f_authfile = { };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}
