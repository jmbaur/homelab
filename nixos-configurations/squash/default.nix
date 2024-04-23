{ pkgs, ... }:
{
  imports = [ ./router.nix ];

  # needed for mt7915 firmware
  hardware.firmware = [ pkgs.linux-firmware ];

  hardware.armada-388-clearfog.enable = true;

  # TODO(jared): use FIT_BEST_MATCH feature in u-boot to choose this automatically
  hardware.deviceTree.name = "armada-388-clearfog-pro.dtb";

  # TODO(jared): this will be the default soon
  boot.kernelPackages = pkgs.linuxPackages_6_6;

  users.users.root.openssh.authorizedKeys.keyFiles = [ pkgs.jmbaur-ssh-keys ];

  custom = {
    server.enable = true;
    image = {
      enable = true;
      encrypt = false;
      # TODO(jared): switched to mpcie card, need to obtain new disk path
      installer.targetDisk = "/dev/disk/by-path/platform-f10a8000.sata-ata-1";
      boot.uboot = {
        enable = true;
        bootMedium.type = "scsi";
      };
    };
  };
}
