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

  boot.kernelPackages = pkgs.linuxPackages_6_0;
  boot.initrd.availableKernelModules = [ "e1000e" ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "America/Los_Angeles";

  services.resolved.enable = true;
  networking = {
    useDHCP = false;
    hostName = "okra";
    useNetworkd = true;
  };
  systemd.network = {
    networks = {
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
    gui.variant = "sway";
    users.jared.enable = true;
    remoteBuilders.aarch64builder.enable = true;
    deployee = {
      enable = true;
      authorizedKeyFiles = [ pkgs.jmbaur-github-ssh-keys ];
    };
    remoteBoot = {
      enable = true;
      authorizedKeyFiles = [ pkgs.jmbaur-github-ssh-keys ];
    };
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
