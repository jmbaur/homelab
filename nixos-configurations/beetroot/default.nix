{ config, lib, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ./disko.nix ];

  tinyboot = {
    enable = true;
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

  boot.initrd.luks.devices.cryptroot.crypttabExtraOpts = lib.mkForce [ "tpm2-device=auto" ];

  # boot.kernelParams = [ "console=uart8250,mmio,0xfe03e000,115200n8" ];
  boot.initrd.availableKernelModules = [ "i915" ];
  boot.initrd.systemd.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_6_1;
  boot.loader.systemd-boot.enable = true;

  hardware.chromebook.enable = true;
  networking.hostName = "beetroot";

  custom = {
    dev.enable = true;
    gui.enable = true;
    laptop.enable = true;
    users.jared = {
      enable = true;
      passwordFile = config.sops.secrets.jared_password.path;
    };
    remoteBuilders.aarch64builder.enable = false;
    wg-mesh = {
      enable = true;
      peers.squash.dnsName = "squash.jmbaur.com";
    };
  };

  nixpkgs.config.allowUnfree = true;

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets.jared_password.neededForUsers = true;
  };

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
