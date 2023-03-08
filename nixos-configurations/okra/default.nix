{ config, lib, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  fileSystems."/".options = [ "noatime" "discard=async" "compress=zstd" ];
  fileSystems."/nix".options = [ "noatime" "discard=async" "compress=zstd" ];
  zramSwap.enable = true;

  boot.initrd.luks.devices."cryptroot".crypttabExtraOpts = [ "tpm2-device=auto" ];
  boot.initrd.systemd.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_6_1;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;

  services.fwupd.enable = true;

  networking.hostName = "okra";

  networking.useDHCP = lib.mkForce false;
  systemd.network.enable = true;

  systemd.network.netdevs.wg0 = {
    enable = false;
    netdevConfig = {
      Name = "wg0";
      Kind = "wireguard";
    };
    wireguardConfig.PrivateKeyFile = "%d/wg0";
    wireguardPeers = [{
      AllowedIPs = [ ];
      Endpoint = "vpn.jmbaur.com:51820";
      PublicKey = "";
    }];
  };

  # public key: zxPDYDdDg8SyHvNhhG3zTq/Ms0tHvnaipdBNGtoXV3c=
  systemd.services.systemd-networkd.serviceConfig.SetCredentialEncrypted = "wg0:k6iUCUh0RJCQyvL8k8q1UyAAAAABAAAADAAAABAAAACJMUd67QrvL9Gmav4AAAAAgAAAAAAAAAALACMA8AAAACAAAAAAngAgd8ATpDnd/btNq2M/Qt8zoWjJy0Zyt1TqLcv+6qIbqQIAEKVbpNq/J4709E/vrfxQyw0xPL61Y6gJLL91UNvG32p6UFLFdEHwm2BS9EHjZTZlr87gF/SuowA/uUCERXezckpw4unlEk+TlyPQVdJel2sS3MHFpP9XQshYm6qJgPQNgiMttgl2AJJWALaUAouta7+r39I3avZqXNG2AE4ACAALAAAAEgAg9gpQ/Gm1MtY4hMLk8o8+Hnp3rKcrPO2Qh2rw9k+Fz+IAEAAgXKWcIqo+gf9eJ7PmbEZ1aE5Glrgpqjh2Rgto/5bCIrT2ClD8abUy1jiEwuTyjz4eenespys87ZCHavD2T4XP4gAAAAB/m+2QtpEUPNhTnabfB+LT9cWGmGxEFzm4RmjRLjr9Mq8Uge0WEubzvNuy9n42sd2Lg6K73cQ7vp4b0y/gQ4yFrjNZWdZLB61QMFPIGWXYlYhdedo=";

  systemd.network.networks = {
    wg0 = {
      name = config.systemd.network.netdevs.wg0.netdevConfig.Name;
      address = [ ];
    };
    ether = {
      name = "en*";
      DHCP = "yes";
    };
  };

  custom.deployee = {
    enable = true;
    authorizedKeyFiles = [ pkgs.jmbaur-github-ssh-keys ];
  };
  custom.remoteBoot.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
