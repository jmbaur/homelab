{ lib, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  tinyboot = {
    enable = false;
    settings = {
      board = "volteer-elemi";
      verifiedBoot = {
        caCertificate = ./x509_ima.pem;
        signingPublicKey = ./x509_ima.der;
        signingPrivateKey = "/etc/keys/privkey_ima.pem";
      };
    };
  };

  hardware.bluetooth.enable = true;

  zramSwap.enable = true;

  boot.initrd.luks.devices.cryptroot.tryEmptyPassphrase = true;
  boot.initrd.luks.devices.cryptroot.crypttabExtraOpts = lib.mkForce [ "tpm2-device=auto" ];

  boot.initrd.systemd.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  fileSystems."/".options = [ "noatime" "discard=async" "compress=zstd" ];
  fileSystems."/nix".options = [ "noatime" "discard=async" "compress=zstd" ];
  fileSystems."/home".options = [ "noatime" "discard=async" "compress=zstd" ];

  hardware.chromebook.enable = true;
  networking.hostName = "beetroot";

  custom = {
    dev.enable = true;
    gui.enable = true;
    laptop.enable = true;
    users.jared.enable = true;
    remoteBuilders.aarch64builder.enable = false;
    wg-mesh = {
      enable = false;
      peers.squash.dnsName = "squash.jmbaur.com";
    };
  };

  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    # substituters = [ "http://carrot.home.arpa" ];
    # trusted-public-keys = [ "carrot.home.arpa:dxp2PztB2LlcVufzgvhsrM9FvrDJcRvP2SqMXr3GSt8=" ];
    # fallback = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

}
