{ pkgs, lib, ... }: {
  imports = [ ./router.nix ./hardware-configuration.nix ];

  nixpkgs.overlays = [
    (_: prev:
      let
        systemdAtLeast254 = (lib.versionAtLeast prev.systemd.version "254");
      in
      {
        systemd = (prev.systemd.override {
          # cross-compiling to armv7 with systemd 254
          withEfi = !systemdAtLeast254;
          withBootloader = !systemdAtLeast254;
        });
      })
  ];

  boot.kernelParams = [ "cfg80211.ieee80211_regdom=US" ];
  boot.initrd.systemd.enable = true;

  networking.hostName = "squash";

  hardware.armada-a38x.enable = true;

  custom = {
    crossCompile.enable = true;
    server.enable = true;
    disableZfs = true;
    deployee = {
      enable = true;
      sshTarget = "root@squash.home.arpa";
      authorizedKeyFiles = [ pkgs.jmbaur-ssh-keys ];
    };
  };

  zramSwap.enable = true;

  system.disableInstallerTools = true;
  system.stateVersion = "23.11";
}
