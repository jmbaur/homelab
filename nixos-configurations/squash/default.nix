{ pkgs, ... }: {
  imports = [ ./router.nix ];

  boot.kernelParams = [ "cfg80211.ieee80211_regdom=US" ];

  hardware.armada-388-clearfog.enable = true;

  users.users.root.openssh.authorizedKeys.keyFiles = [ pkgs.jmbaur-ssh-keys ];

  custom = {
    server.enable = true;
    disableZfs = true;
    image = {
      enable = true;
      encrypt = false;
      primaryDisk = "/dev/disk/by-path/TODO";
      bootVariant = "fit-image";
      ubootBootMedium.type = "mmc"; # TODO(jared): This should probably be sata?
    };
  };
}
