{ config, pkgs, ... }: {
  imports = [
    ./cache.nix
    ./hardware-configuration.nix
    ./networking.nix
    ./nfs.nix
  ];

  hardware.lx2k.enable = true;

  fileSystems = {
    "/".options = [ "noatime" "discard=async" "compress=zstd" ];
    "/nix".options = [ "noatime" "discard=async" "compress=zstd" ];
    "/var".options = [ "noatime" "discard=async" "compress=zstd" ];
    "/home".options = [ "noatime" "discard=async" "compress=zstd" ];
    "/var/lib".options = [ "noatime" "discard=async" "compress=zstd" ];
    "/var/storage".options = [ "noatime" "autodefrag" "compress=zstd" ];
  };
  zramSwap.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets.nix-cache-signing-key = { owner = config.users.users.builder.name; group = config.users.users.builder.group; };
    secrets.wg0 = { mode = "0640"; group = config.users.groups.systemd-network.name; };
  };

  nix.settings.trusted-users = [ config.users.users.builder.name ];
  users.users.builder = {
    isNormalUser = true;
    openssh.authorizedKeys = {
      keyFiles = [ pkgs.jmbaur-github-ssh-keys ];
      keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIer9NAxijyKMklfKe4yiZXOCyMa5RchUKt4Y4DK7SRT root@beetroot" ];
    };
  };

  custom = {
    server.enable = true;
    deployee = {
      enable = true;
      authorizedKeyFiles = [ pkgs.jmbaur-github-ssh-keys ];
    };
    remoteBoot = {
      enable = true;
      authorizedKeyFiles = config.custom.deployee.authorizedKeyFiles;
    };
  };

  services.runner = {
    enable = false;
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
  services.prometheus.exporters.node = {
    enable = true;
    openFirewall = false;
    enabledCollectors = [ "ethtool" "network_route" "systemd" ];
  };

  programs.flashrom.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
