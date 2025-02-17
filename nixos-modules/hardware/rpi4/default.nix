{
  config,
  lib,
  pkgs,
  ...
}:

let
  firmwareImage = pkgs.callPackage ./firmware-image.nix {
    deviceTreeFile = "${config.hardware.deviceTree.package}/${config.hardware.deviceTree.name}";
  };
in
{
  options.hardware.rpi4.enable = lib.mkEnableOption "rpi4 hardware support";

  config = lib.mkIf config.hardware.rpi4.enable {
    nixpkgs.hostPlatform = "aarch64-linux";

    # Undo the settings we set in <homelab/nixos-modules/server.nix>, they
    # doesn't work on the RPI4.
    #
    # TODO(jared): figure out how to get rid of this.
    systemd.watchdog = {
      runtimeTime = null;
      rebootTime = null;
    };

    system.build.firmwareImage = firmwareImage;

    hardware.deviceTree = {
      name = "broadcom/bcm2711-rpi-4-b.dtb";
      overlays = [
        {
          name = "rpi4-cma-overlay";
          dtsText = ''
            /dts-v1/;
            /plugin/;

            / {
              compatible = "brcm,bcm2711";

              fragment@0 {
                target = <&cma>;
                __overlay__ {
                  size = <(512 * 1024 * 1024)>;
                };
              };
            };
          '';
        }
      ];
    };

    # Pins 6,8,10 on the 40-pin layout.
    #  6 -> gnd
    #  8 -> tx
    # 10 -> rx
    boot.kernelParams = [ "console=ttyS1,115200" ];

    environment.etc."fw_env.config".text = ''
      ${config.boot.loader.efi.efiSysMountPoint}/uboot.env 0x0000 0x10000
    '';

    nixpkgs.overlays = [
      (_: prev: { libcec = prev.libcec.override { withLibraspberrypi = true; }; })
    ];

    environment.systemPackages = [
      # install libcec, which includes cec-client (requires root or "video" group, see udev rule below)
      # scan for devices: `echo 'scan' | cec-client -s -d 1`
      # set pi as active source: `echo 'as' | cec-client -s -d 1`
      pkgs.libcec

      pkgs.libraspberrypi
      pkgs.raspberrypi-eeprom
      pkgs.uboot-env-tools
      (pkgs.writeShellApplication {
        name = "update-firmware";
        runtimeInputs = [
          pkgs.xz
          pkgs.coreutils
        ];
        text = ''
          xz -d <${firmwareImage} | dd bs=4M status=progress oflag=sync of=/dev/disk/by-label/${firmwareImage.label}
        '';
      })
    ];

    boot.initrd.systemd.tpm2.enable = lib.mkDefault false;
    custom.recovery.modules = [
      {
        boot.initrd.systemd.tpm2.enable = false;
      }
    ];

    boot.initrd.availableKernelModules = [
      "usbhid"
      "usb_storage"
      "vc4"
      "pcie_brcmstb" # required for the pcie bus to work
      "reset-raspberrypi" # required for vl805 firmware to load
    ];

    # TODO(jared): filter this down to only the files we need
    # Required for the Wireless firmware
    hardware.enableRedistributableFirmware = true;

    services.udev.extraRules = ''
      # allow access to raspi cec device for video group (and optionally register it as a systemd device, used below)
      KERNEL=="vchiq", GROUP="video", MODE="0660", TAG+="systemd", ENV{SYSTEMD_ALIAS}="/dev/vchiq"
    '';
  };
}
