{ pkgs, ... }: {
  imports = [ ./router.nix ./hardware-configuration.nix ];

  boot.kernelParams = [ "cfg80211.ieee80211_regdom=US" ];
  boot.initrd.systemd.enable = true;

  hardware.armada-388-clearfog.enable = true;

  custom = {
    server.enable = true;
    disableZfs = true;
    deployee = {
      enable = true;
      sshTarget = "root@squash.home.arpa";
      authorizedKeyFiles = [ pkgs.jmbaur-ssh-keys ];
    };
  };

  zramSwap.enable = true;
}
