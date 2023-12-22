{ pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  fileSystems."/".options = [ "discard=async" "noatime" "compress=zstd" ];
  fileSystems."/nix".options = [ "discard=async" "noatime" "compress=zstd" ];
  fileSystems."/home".options = [ "discard=async" "noatime" "compress=zstd" ];

  services.fwupd.enable = true;

  zramSwap.enable = true;

  boot.initrd.luks.devices."cryptroot".tryEmptyPassphrase = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  custom = {
    server.enable = true;
    remoteBoot.enable = false;
    deployee = {
      enable = true;
      sshTarget = "root@artichoke.home.arpa";
      authorizedKeyFiles = [ pkgs.jmbaur-ssh-keys ];
    };
  };

  services.nfs.server.enable = true;
}
