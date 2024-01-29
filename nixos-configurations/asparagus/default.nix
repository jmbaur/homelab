{ pkgs, ... }: {
  hardware.clearfog-cn913x.enable = true;

  users.users.root.openssh.authorizedKeys.keyFiles = [ pkgs.jmbaur-ssh-keys ];

  custom.image = {
    enable = true;
    encrypt = false;
    primaryDisk = "/dev/disk/by-path/TODO";
    uboot = {
      enable = true;
      bootMedium.type = "mmc"; # TODO(jared): This should probably be sata?
    };
  };
}
