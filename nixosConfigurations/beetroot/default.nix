{ config, lib, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  hardware.bluetooth.enable = true;
  hardware.enableRedistributableFirmware = true;
  hardware.thinkpad-x13s.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.systemd.enable = true;

  users.users.jared = {
    isNormalUser = true;
    description = "Jared Baur";
    shell = pkgs.bash;
    extraGroups = [ "adbusers" "dialout" "wheel" ];
  };

  custom = {
    common.enable = true;
    dev.enable = true;
    gui.enable = true;
    laptop.enable = true;
  };

  networking = {
    useDHCP = lib.mkForce false;
    hostName = "beetroot";
    useNetworkd = true;
    wireless.enable = true;
  };
  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
    networks = {
      wired = {
        name = "en*";
        DHCP = "yes";
        dhcpV4Config.RouteMetric = 1024;
        ipv6AcceptRAConfig.RouteMetric = 1024;
        networkConfig.IPv6PrivacyExtensions = "kernel";
      };
      wireless = {
        name = "wl*";
        DHCP = "yes";
        dhcpV4Config.RouteMetric = config.systemd.network.networks.wired.dhcpV4Config.RouteMetric * 2;
        ipv6AcceptRAConfig.RouteMetric = config.systemd.network.networks.wired.ipv6AcceptRAConfig.RouteMetric * 2;
        networkConfig.IPv6PrivacyExtensions = "kernel";
      };
    };
  };
  services.resolved.enable = true;

  services.snapper.configs.home = {
    subvolume = "/home";
    extraConfig = ''
      TIMELINE_CREATE=yes
      TIMELINE_CLEANUP=yes
    '';
  };

  nixpkgs.config.allowUnfree = true;

  services.fwupd.enable = true;
  programs.adb.enable = true;
  programs.nix-ld.enable = true;

  home-manager.users.jared = { config, systemConfig, ... }: {
    services.kanshi = {
      profiles = {
        default = {
          outputs = [
            { criteria = "eDP-1"; }
          ];
        };
        docked = {
          outputs = config.services.kanshi.profiles.default.outputs ++ [
            { criteria = "Lenovo Group Limited LEN P24q-20 V306P4GR"; mode = "2560x1440@74.78Hz"; }
          ];
        };
      };
    };
    home.packages = with pkgs; [
      age-plugin-yubikey
      element-desktop-wayland
      firefox-wayland
      yubikey-manager
      yubikey-personalization
    ];
    programs.git = {
      userEmail = "jaredbaur@fastmail.com";
      userName = systemConfig.users.users.jared.description;
      extraConfig = {
        user.signingKey = "key::sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBhCHaXn5ghEJQVpVZr4hOajD6Zp/0PO4wlymwfrg/S5AAAABHNzaDo=";
        gpg.format = "ssh";
        gpg.ssh.defaultKeyCommand = "ssh-add -L";
      };
    };
  };

  warnings = [
    "bitwarden, discord, signal-desktop, & spotify are wanted but currently unsupported on aarch64-linux"
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}
