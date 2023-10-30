{ lib, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  tinyboot = {
    enable = false;
    board = "brya-banshee";
    verifiedBoot = {
      caCertificate = ./x509_ima.pem;
      signingPublicKey = ./x509_ima.der;
      signingPrivateKey = "/etc/keys/privkey_ima.pem";
    };
  };


  boot.kernelPatches = [{
    name = "google-firmware";
    patch = null;
    extraStructuredConfig = with lib.kernel; {
      GOOGLE_FIRMWARE = yes;
      GOOGLE_COREBOOT_TABLE = yes;
      GOOGLE_VPD = yes;
    };
  }];

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
    gui = {
      enable = true;
      displays.laptopDisplay = {
        match = "eDP-1";
        isInternal = true;
        scale = 1.25;
      };
    };
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
}
