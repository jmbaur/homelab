{ lib, pkgs, ... }: {
  imports = [ ./router.nix ];

  boot.kernelParams = [ "cfg80211.ieee80211_regdom=US" ];

  hardware.armada-388-clearfog.enable = true;

  boot.initrd.systemd.emergencyAccess = lib.warn "initrd emergency access enabled" true;

  users.users.root.openssh.authorizedKeys.keyFiles = [ pkgs.jmbaur-ssh-keys ];

  custom = {
    server.enable = true;
    image = {
      enable = true;
      encrypt = false;
      primaryDisk = "/dev/disk/by-path/platform-f10a8000.sata-ata-1";
      uboot = {
        enable = true;
        bootMedium.type = "scsi";
      };
    };
  };
}
