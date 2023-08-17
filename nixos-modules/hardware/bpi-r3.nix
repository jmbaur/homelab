{ config, lib, pkgs, ... }: {
  options.hardware.bpi-r3.enable = lib.mkEnableOption "bananapi r3";
  config = lib.mkIf config.hardware.bpi-r3.enable {
    boot.kernelPackages = pkgs.linuxPackages_latest;

    # linux kernel 6.3+ requires using extra flags for memfd_create that only
    # exist starting in systemd-stable v254
    nixpkgs.overlays = lib.optional
      (!lib.versionAtLeast pkgs.systemd.version "254")
      (_: prev: {
        systemd = prev.systemd.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ (with prev; [
            (fetchpatch {
              url = "https://github.com/systemd/systemd-stable/commit/8cb0a001d8193721af98a448d5b3615ac5e263f1.diff";
              hash = "sha256-E1rsAhhmBQMc1w3dI7GD/dmffTFTWYHtiM/DQjzuVgc=";
            })
            (fetchpatch {
              url = "https://github.com/systemd/systemd-stable/commit/ad62530ebb397982a73266a07ac6f182e47922de.diff";
              hash = "sha256-6oLb7W78uYHmSp/hfesjunaaxSigfrgpcekVJ1Ho4N8=";
            })
            (fetchpatch {
              url = "https://github.com/systemd/systemd-stable/commit/c29715a8f77d96cd731b4a3083b3a852b3b61eb8.diff";
              hash = "sha256-2I1afgVHdi4c+k8zUL1TI1gxRM8YPVEMNoy4twnaUSk=";
            })
          ]);
        });
      });

    boot.kernelParams = [ "console=ttyS0,115200" ];

    # u-boot looks for $fdtfile on the ESP at /dtb
    boot.loader.systemd-boot.extraFiles."dtb" = "${config.hardware.deviceTree.package}";
    boot.loader.grub.extraFiles."dtb" = "${config.hardware.deviceTree.package}";

    hardware.deviceTree.enable = true;
    hardware.deviceTree.name = "mediatek/mt7986a-bananapi-bpi-r3.dtb";
    hardware.deviceTree.overlays = [
      {
        name = "mt7986a-bananapi-bpi-r3-nand.dtbo";
        dtboFile = "${config.boot.kernelPackages.kernel}/dtbs/mediatek/mt7986a-bananapi-bpi-r3-nand.dtbo";
      }
      {
        name = "mt7986a-bananapi-bpi-r3-sd.dtbo";
        dtboFile = "${config.boot.kernelPackages.kernel}/dtbs/mediatek/mt7986a-bananapi-bpi-r3-sd.dtbo";
      }
    ];
  };
}
