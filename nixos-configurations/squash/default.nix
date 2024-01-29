{ lib, pkgs, ... }: {
  imports = [ ./router.nix ];

  boot.kernelParams = [ "cfg80211.ieee80211_regdom=US" ];

  # needed for mt7915 firmware
  hardware.firmware = [ pkgs.linux-firmware ];

  hardware.armada-388-clearfog.enable = true;

  # TODO(jared): use FIT_BEST_MATCH feature in u-boot to choose this automatically
  # TODO(jared): latest linux kernels have <vendor>/<dtb> for armv7
  hardware.deviceTree.name = "armada-388-clearfog-pro.dtb";

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
