{ config, lib, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

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
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets.wg-home = {
      mode = "0640";
      owner = config.users.users.root.name;
      group = config.users.groups.systemd-network.name;
    };
    secrets.wg-mv = {
      mode = "0640";
      owner = config.users.users.root.name;
      group = config.users.groups.systemd-network.name;
    };
  };

  networking = {
    useDHCP = false;
    hostName = "beetroot";
    useNetworkd = true;
    wireless.iwd.enable = true;
  };

  # don't enable this for a laptop
  systemd.services."systemd-networkd-wait-online".enable = false;

  systemd.network = {
    enable = true;

    netdevs = {
      wg-mv = {
        netdevConfig = { Name = "wg-mv"; Kind = "wireguard"; };
        wireguardConfig = {
          PrivateKeyFile = "/run/secrets/wg-mv";
          FirewallMark = 34952;
          RouteTable = "off";
        };
      };
    };

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

      # https://wiki.archlinux.org/title/Mullvad#With_systemd-networkd
      wg-mv = {
        matchConfig.Name = config.systemd.network.netdevs.wg-mv.netdevConfig.Name;
        # Manual activation: sudo networkctl up <iface>
        linkConfig.ActivationPolicy = "manual";
        networkConfig = {
          DNSDefaultRoute = "yes";
          Domains = "~.";
        };
        routes = [
          {
            routeConfig = {
              Gateway = "0.0.0.0";
              GatewayOnLink = true;
              Table = 1000;
            };
          }
          {
            routeConfig = {
              Gateway = "::";
              GatewayOnLink = true;
              Table = 1000;
            };
          }
        ];
        routingPolicyRules = [
          {
            routingPolicyRuleConfig = {
              SuppressPrefixLength = 0;
              Family = "both";
              Priority = 999;
              Table = "main";
            };
          }
          {
            routingPolicyRuleConfig = {
              Family = "both";
              FirewallMark = 34952;
              InvertRule = true;
              Table = 1000;
              Priority = 10;
            };
          }
        ];
      };
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
  services.openssh = {
    enable = true;
    listenAddresses = builtins.map (addr: { inherit addr; port = 22; }) [ "127.0.0.1" "::1" ];
    allowSFTP = false;
    passwordAuthentication = false;
    startWhenNeeded = true;
  };
  programs.nix-ld.enable = true;

  environment.pathsToLink = [ "/share/nix-direnv" ];
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
