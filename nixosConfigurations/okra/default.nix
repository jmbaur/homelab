{ pkgs, ... }: {
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

  custom.basicNetwork.enable = true;
  custom.basicNetwork.hasWireless = false; # it actually does, but we don't use it
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
