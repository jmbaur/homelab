{ pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];
  hardware.bluetooth.enable = true;

  zramSwap.enable = true;

  environment.systemPackages = [ pkgs.sbctl ];

  boot.initrd.luks.devices.cryptroot.crypttabExtraOpts = [ "tpm2-device=auto" ];

  fileSystems."/".options = [ "noatime" "compress=zstd" "discard=async" ];
  fileSystems."/nix".options = [ "noatime" "compress=zstd" "discard=async" ];
  fileSystems."/home".options = [ "noatime" "compress=zstd" "discard=async" ];

  boot.initrd.systemd.enable = true;

  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
  };

  networking.hostName = "potato";

  services.fwupd.enable = true;

  users.mutableUsers = true;

  custom = {
    dev.enable = true;
    gui.enable = true;
    laptop.enable = true;
    users.jared.enable = true;
    remoteBuilders.aarch64builder.enable = false;
    wg-mesh = {
      enable = false;
      dns = true;
      # peers.squash.extraConfig.Endpoint = "squash.home.arpa:51820"; # "vpn.jmbaur.com:51820";
    };
  };

  nixpkgs.config.allowUnfree = true;

  programs.adb.enable = true;

  nix.settings = {
    substituters = [ "http://carrot.home.arpa" ];
    trusted-public-keys = [ "carrot.home.arpa:dxp2PztB2LlcVufzgvhsrM9FvrDJcRvP2SqMXr3GSt8=" ];
    fallback = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

}
