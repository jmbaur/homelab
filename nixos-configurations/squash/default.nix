{
  config,
  lib,
  pkgs,
  ...
}:

let
  tinybootKernel = pkgs.linuxKernel.manualConfig {
    inherit (pkgs.linux_7_2) src version;
    configfile = ./tinyboot.config;
    # Same fixes the booted kernel needs. kexec is the whole of what tinyboot
    # does, and the rng90 is this board's only source of entropy. Only the
    # patches carry over; tinyboot.config is what sets the kconfig here.
    inherit (config.boot) kernelPatches;
  };

  # u-boot SPL boots this straight out of SPI flash, so it has to carry
  # everything tinyboot needs: the kernel, its initrd and the fdt.
  fitImage = pkgs.callPackage (
    {
      runCommand,
      dtc,
      ubootTools,
    }:
    runCommand "squash-tinyboot-fitImage"
      {
        depsBuildBuild = [
          dtc
          ubootTools
        ];
      }
      ''
        cp ${tinybootKernel}/zImage kernel
        # tinyboot hands /sys/firmware/fdt to whatever it kexecs, so this is
        # also the fdt the booted system ends up with, and the only place the
        # deviceTree overlays can reach either kernel from.
        cp ${config.hardware.deviceTree.package}/${config.hardware.deviceTree.name} dtb
        cp ${pkgs.tinyboot}/${pkgs.tinyboot.initrdFile} initrd
        cp ${./tinyboot.its} image.its
        # -E keeps image data out of the FIT structure, which SPL buffers in
        # full before parsing it. -B 0x8 pins the structure and data offsets to
        # a fixed alignment rather than one that falls out of the last image's
        # type, which is what mkimage does on its own.
        mkimage -E -B 0x8 -f image.its $out
      ''
  ) { };
in
{
  hardware.firmware = [
    pkgs.wireless-regdb
    (pkgs.extractLinuxFirmwareDirectory "mediatek")
  ];

  hardware.armada-388-clearfog.enable = true;
  hardware.armada-388-clearfog.falconPayload = fitImage;

  boot.loader.tinyboot.enable = true;

  # TODO(jared): use FIT_BEST_MATCH feature in u-boot to choose this automatically
  hardware.deviceTree.name = "armada-388-clearfog-pro.dtb";

  boot.initrd.availableKernelModules = [ "rng90" ];

  boot.kernelPatches = [
    {
      name = "rng90-support";
      patch = ./0001-char-hw_random-add-RNG90-driver.patch;
      structuredExtraConfig = {
        HW_RANDOM_RNG90 = lib.kernel.module;
      };
    }
  ];

  hardware.deviceTree.overlays = [
    {
      name = "rng90";
      dtsFile = ./rng90.dtso;
    }
  ];

  custom = {
    server.enable = true;
    basicNetwork.enable = !config.router.enable;
    recovery.targetDisk = "/dev/disk/by-path/platform-f10a8000.sata-ata-1.0";
  };

  # Keep "wlan*" names for mt7915e card
  systemd.network.links."10-mt7915" = {
    matchConfig.Path = "platform-soc:pcie-pci-0000:01:00.0";
    linkConfig.NamePolicy = "kernel";
  };

  # hostapd tuning config for mt7915e
  services.hostapd = {
    radios.wlan0 = {
      band = "2g";
      countryCode = "US";
      wifi5.enable = false;
      wifi6.enable = false;
      wifi7.enable = false;
      wifi4 = {
        enable = true;
        capabilities = [
          "RXLDPC"
          "HT40+"
          "GF"
          "SHORT-GI-20"
          "SHORT-GI-40"
          "TX-STBC"
          "RX-STBC1"
          "MAX-AMSDU-7935"
        ];
      };
    };
    radios.wlan1 = {
      band = "5g";
      countryCode = "US";
      wifi7.enable = false;
      wifi4 = {
        enable = true;
        capabilities = [
          "RXLDPC"
          "HT40+"
          "GF"
          "SHORT-GI-20"
          "SHORT-GI-40"
          "TX-STBC"
          "RX-STBC1"
          "MAX-AMSDU-7935"
        ];
      };
      wifi5 = {
        enable = true;
        capabilities = [
          "MAX-MPDU-7991"
          "RXLDPC"
          "SHORT-GI-80"
          "TX-STBC-2BY1"
          "SU-BEAMFORMER"
          "SU-BEAMFORMEE"
          "MU-BEAMFORMER"
          "MU-BEAMFORMEE"
          "RX-ANTENNA-PATTERN"
          "TX-ANTENNA-PATTERN"
        ];
      };
      wifi6 = {
        enable = true;
        operatingChannelWidth = "80";
        singleUserBeamformer = true;
        singleUserBeamformee = true;
        multiUserBeamformer = true;
      };
    };
  };
}
