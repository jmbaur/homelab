{ config, pkgs, ... }: {
  imports = [
    ./networking.nix
    ./hardware-configuration.nix
  ];

  fileSystems = {
    "/".options = [ "noatime" "discard=async" "compress=zstd" ];
    "/nix".options = [ "noatime" "discard=async" "compress=zstd" ];
    "/var".options = [ "noatime" "discard=async" "compress=zstd" ];
    "/home".options = [ "noatime" "discard=async" "compress=zstd" ];
    "/var/lib".options = [ "noatime" "discard=async" "compress=zstd" ];
  };
  zramSwap.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets."wg/www/kale" = {
      mode = "0640";
      group = config.users.groups.systemd-network.name;
    };
  };

  nix.settings.trusted-users = [ config.users.users.builder.name ];
  users.users.builder = {
    isNormalUser = true;
    openssh.authorizedKeys = {
      keyFiles = [ pkgs.jmbaur-github-ssh-keys ];
      keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJawyN2+eugTUPbfxqpqKAPOh8qJ9/bT3Lq1Dq2YAzFt root@beetroot" ];
    };
  };

  custom = {
    deployee = {
      enable = true;
      authorizedKeyFiles = [ pkgs.jmbaur-github-ssh-keys ];
    };
    remoteBoot = {
      enable = true;
      authorizedKeyFiles = config.custom.deployee.authorizedKeyFiles;
    };
    wgWwwPeer.enable = true;
  };

  services.runner = {
    enable = true;
    runs = {
      runner-nix = {
        environment.RUST_LOG = "debug";
        listenAddresses = [ "8000" ];
        adapter = "github";
        command = "${pkgs.nix}/bin/nix build github:jmbaur/runner-nix#default --no-link --extra-experimental-features nix-command --extra-experimental-features flakes --print-build-logs --rebuild";
      };
      artichoke = {
        environment.RUST_LOG = "debug";
        listenAddresses = [ "8001" ];
        adapter = "github";
        command = "${pkgs.nix}/bin/nix build github:jmbaur/homelab#nixosConfigurations.artichoke.config.system.build.toplevel --no-link --extra-experimental-features nix-command --extra-experimental-features flakes --print-build-logs --rebuild";
      };
    };
  };

  services.journald.enableHttpGateway = true;
  services.prometheus.exporters = {
    node = {
      enable = true;
      openFirewall = false;
      enabledCollectors = [ "ethtool" "network_route" "systemd" ];
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
