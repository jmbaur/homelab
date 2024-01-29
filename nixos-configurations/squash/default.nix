{ pkgs, ... }: {
  imports = [ ./router.nix ];

  boot.kernelParams = [ "cfg80211.ieee80211_regdom=US" ];

  hardware.armada-388-clearfog.enable = true;

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
        # The default load address is 0x800000, so let's leave up to 32MiB for
        # the fit-image.
        kernelLoadAddress = "0x2800000";
      };
    };
  };
}
