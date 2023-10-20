{ pkgs, lib, ... }: {
  imports = [ ./router.nix ./hardware-configuration.nix ];

  nixpkgs.overlays = [
    (final: prev:
      let
        systemdAtLeast254 = (lib.versionAtLeast prev.systemd.version "254");
      in
      {
        systemd = (prev.systemd.overrideAttrs (old: lib.optionalAttrs systemdAtLeast254 {
          # Fix cross-compiling to armv7 with systemd 254. Remove once changes
          # from https://github.com/NixOS/nixpkgs/pull/258373 are in our
          # nixpkgs. See https://nixpk.gs/pr-tracker.html?pr=258373.
          patches = (old.patches or [ ]) ++ [
            (final.fetchpatch {
              url = "https://github.com/systemd/systemd/commit/cecbb162a3134b43d2ca160e13198c73ff34c3ef.patch";
              hash = "sha256-hWpUosTDA18mYm5nIb9KnjwOlnzbEHgzha/WpyHoC54=";
            })
          ];
        }));
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
