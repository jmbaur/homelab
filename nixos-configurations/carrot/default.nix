{ config, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  fileSystems."/".options = [ "noatime" "discard=async" "compress=zstd" ];
  fileSystems."/nix".options = [ "noatime" "discard=async" "compress=zstd" ];
  fileSystems."/home".options = [ "noatime" "discard=async" "compress=zstd" ];

  zramSwap.enable = true;

  # boot.kernelParams = [
  #   "console=ttyS0"
  #   "console=uart8250,mmio,0xfe030000,115200n8"
  #   "console=uart8250,mmio,0x91336000,115200n8"
  # ];

  tinyboot = {
    board = "fizz-fizz";
    flashrom.package = config.programs.flashrom.package;
  };

  boot.loader.systemd-boot.enable = true;
  boot.initrd.systemd.enable = true;

  hardware.chromebook.enable = true;

  networking.hostName = "carrot";
  networking.wireless.enable = true;

  custom = {
    server.enable = true;
    basicNetwork = {
      enable = true;
      hasWireless = false;
    };
    remoteBoot.enable = false;
    deployee = {
      enable = true;
      sshTarget = "root@carrot.home.arpa";
      authorizedKeyFiles = [ pkgs.jmbaur-github-ssh-keys ];
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
