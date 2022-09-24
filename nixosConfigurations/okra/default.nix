{ config, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];
  hardware.bluetooth.enable = true;

  fileSystems = {
    "/".options = [ "noatime" "discard=async" "compress=zstd" ];
    "/nix".options = [ "noatime" "discard=async" "compress=zstd" ];
    "/home".options = [ "noatime" "discard=async" "compress=zstd" ];
    "/home/.snapshots".options = [ "noatime" "discard=async" "compress=zstd" ];
  };

  zramSwap.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_5_19;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "America/Los_Angeles";

  services.resolved.enable = true;
  networking = {
    useDHCP = false;
    hostName = "okra";
    useNetworkd = true;
    wireless.enable = true;
  };
  systemd.network = {
    networks = {
      wireless = {
        name = "wl*";
        DHCP = "yes";
        networkConfig.IPv6PrivacyExtensions = true;
        dhcpV4Config.ClientIdentifier = "mac";
        dhcpV4Config.RouteMetric = config.systemd.network.networks.wired.dhcpV4Config.RouteMetric * 2;
        ipv6AcceptRAConfig.RouteMetric = config.systemd.network.networks.wired.ipv6AcceptRAConfig.RouteMetric * 2;
      };
      wired = {
        name = "en*";
        DHCP = "yes";
        networkConfig.IPv6PrivacyExtensions = true;
        dhcpV4Config.ClientIdentifier = "mac";
        dhcpV4Config.RouteMetric = 1024;
        ipv6AcceptRAConfig.RouteMetric = 1024;
      };
    };
  };

  custom = {
    common.enable = true;
    dev.enable = true;
    gui.enable = true;
    users.jared.enable = true;
  };

  home-manager.users.jared = { systemConfig, config, pkgs, ... }: {
    programs.git = {
      userEmail = "jaredbaur@fastmail.com";
      userName = systemConfig.users.users.jared.description;
      extraConfig = {
        commit.gpgSign = true;
        gpg.format = "ssh";
        gpg.ssh.defaultKeyCommand = "ssh-add -L";
        gpg.ssh.allowedSignersFile = toString (pkgs.writeText "allowedSignersFile" ''
          ${config.programs.git.userEmail} sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBhCHaXn5ghEJQVpVZr4hOajD6Zp/0PO4wlymwfrg/S5AAAABHNzaDo=
          ${config.programs.git.userEmail} sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIHRlxBSW3BzX33FG7444p/M5lb9jYR5OkjS2jPpnuXozAAAABHNzaDo=
        '');
        user.signingKey = "key::sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBhCHaXn5ghEJQVpVZr4hOajD6Zp/0PO4wlymwfrg/S5AAAABHNzaDo=";
      };
    };
    programs.ssh = {
      enable = true;
      matchBlocks = {
        "*.mgmt.home.arpa".forwardAgent = true;
        work = {
          user = "jbaur";
          hostname = "dev.work.home.arpa";
          dynamicForwards = [{ port = 9050; }];
          localForwards = [
            { bind.port = 1025; host.address = "localhost"; host.port = 1025; }
            { bind.port = 8000; host.address = "localhost"; host.port = 8000; }
          ];
        };
      };
    };

    home.packages = with pkgs; [
      age-plugin-yubikey
      bitwarden
      discord-wayland
      element-desktop-wayland
      firefox-wayland
      freerdp
      google-chrome-wayland
      outlook-webapp
      qutebrowser
      signal-desktop-wayland
      slack-wayland
      spotify
      teams-webapp
      yubikey-manager
      yubikey-personalization
    ];
  };

  nixpkgs.config.allowUnfree = true;

  services.fwupd.enable = true;

  security.pam.u2f = {
    enable = true;
    cue = true;
    origin = "pam://homelab";
    authFile = config.age.secrets.pam_u2f_authfile.path;
  };

  age.secrets.pam_u2f_authfile.file = ../../secrets/pam_u2f_authfile.age;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}
