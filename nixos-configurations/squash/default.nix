{ pkgs, ... }: {
  imports = [ ./router.nix ./hardware-configuration.nix ];

  boot.kernelParams = [ "cfg80211.ieee80211_regdom=US" ];
  boot.initrd.systemd.enable = true;

  networking.hostName = "squash";

  hardware.armada-a38x.enable = true;

  nixpkgs.overlays = [
    (_: prev: {
      systemd = prev.systemd.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          (prev.fetchpatch {
            name = "add-arm_fadvise64_64-to-system-service-group";
            url = "https://github.com/systemd/systemd/commit/9f52c2bda8f5042eabf661d05600092326d67f60.patch";
            hash = "sha256-iFtlSDoaehEhHwS682tv90a4Qf4VITr6N9lDK2ItwuE=";
          })
        ];
      });
    })
  ];

  custom = {
    crossCompile.enable = true;
    server.enable = true;
    disableZfs = true;
    deployee = {
      enable = true;
      sshTarget = "root@squash.home.arpa";
      authorizedKeyFiles = [ pkgs.jmbaur-github-ssh-keys ];
    };
  };

  zramSwap.enable = true;
  system.stateVersion = "23.11";
}
