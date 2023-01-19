{ config, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];
  hardware.bluetooth.enable = true;

  zramSwap.enable = true;

  boot.initrd.luks.devices."cryptroot".crypttabExtraOpts = [ "fido2-device=auto" ];
  fileSystems."/".options = [ "noatime" "discard=async" "compress=zstd" ];
  fileSystems."/nix".options = [ "noatime" "discard=async" "compress=zstd" ];
  fileSystems."/home".options = [ "noatime" "discard=async" "compress=zstd" ];

  boot.initrd.availableKernelModules = [ "i915" ];
  boot.initrd.systemd.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_6_1;
  boot.loader = {
    grub = {
      enable = true;
      device = "nodev";
      efiInstallAsRemovable = true;
      copyKernels = true;
      efiSupport = true;
    };
    efi.canTouchEfiVariables = false;
  };

  time.timeZone = "America/Los_Angeles";

  hardware.chromebook.enable = true;

  networking = {
    useDHCP = false;
    hostName = "beetroot";
    useNetworkd = true;
    wireless.enable = true;
  };
  systemd.network = {
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

  users.mutableUsers = true;
  custom = {
    dev.enable = true;
    gui.enable = true;
    laptop.enable = true;
    users.jared = {
      enable = true;
      # passwordFile = config.sops.secrets.jared_password.path;
    };
    remoteBuilders.aarch64builder.enable = true;
  };

  nixpkgs.config.allowUnfree = true;

  # security.pam.u2f = {
  # enable = true;
  # cue = true;
  # origin = "pam://homelab";
  # authFile = config.sops.secrets.pam_u2f_authfile.path;
  # };

  # sops = {
  # defaultSopsFile = ./secrets.yaml;
  # secrets = {
  # pam_u2f_authfile = { };
  # jared_password.neededForUsers = true;
  # "rdp/domain".owner = config.users.users.jared.name;
  # "rdp/user".owner = config.users.users.jared.name;
  # "rdp/password".owner = config.users.users.jared.name;
  # };
  # };

  home-manager.users.jared = { config, pkgs, ... }: {
    services.kanshi = {
      profiles = {
        default = { outputs = [{ criteria = "eDP-1"; }]; };
        docked = {
          outputs = config.services.kanshi.profiles.default.outputs ++ [
            { criteria = "Lenovo Group Limited LEN P24q-20 V306P4GR"; mode = "2560x1440@74.78Hz"; }
          ];
        };
      };
    };

    home.packages = with pkgs; [
      age-plugin-yubikey
      bitwarden
      brave-wayland
      chromium-wayland
      discord-wayland
      element-desktop-wayland
      firefox-wayland
      freerdp
      librewolf-wayland
      outlook-webapp
      signal-desktop-wayland
      slack-wayland
      spotify
      teams-webapp
      (writeShellScriptBin "work-browser" "${chromium-wayland}/bin/chromium --user-data-dir=$HOME/.config/chromium-work --proxy-server=socks5://localhost:9050")
      (writeShellScriptBin "rdp" "${pkgs.freerdp}/bin/wlfreerdp /sec:tls /cert:tofu /v:laptop.work.home.arpa -grab-keyboard +auto-reconnect")
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

}
