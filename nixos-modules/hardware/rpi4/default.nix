{
  config,
  lib,
  pkgs,
  ...
}:

let
  firmwareImage = pkgs.callPackage ./firmware-image.nix { };
in
{
  options.hardware.rpi4.enable = lib.mkEnableOption "rpi4 hardware support";

  config = lib.mkIf config.hardware.rpi4.enable {
    nixpkgs.hostPlatform = "aarch64-linux";

    # Undo the settings we set in <homelab/nixos-modules/server.nix>, they
    # doesn't work on the RPI4. TODO(jared): figure out how to get rid of
    # this.
    systemd.watchdog = {
      runtimeTime = null;
      rebootTime = null;
    };

    system.build.firmwareImage = firmwareImage;

    hardware.deviceTree.enable = true;
    hardware.deviceTree.name = "broadcom/bcm2711-rpi-4-b.dtb";

    boot.kernelParams = [ "console=ttyS1,115200" ];

    environment.etc."fw_env.config".text = ''
      ${config.boot.loader.efi.efiSysMountPoint}/uboot.env 0x0000 0x10000
    '';

    environment.systemPackages = [
      pkgs.raspberrypi-eeprom
      pkgs.uboot-env-tools
    ];

    boot.initrd.availableKernelModules = [
      "usbhid"
      "usb_storage"
      "vc4"
      "pcie_brcmstb" # required for the pcie bus to work
      "reset-raspberrypi" # required for vl805 firmware to load
    ];

    # Required for the Wireless firmware
    hardware.enableRedistributableFirmware = true;

    nixpkgs.overlays = [
      (_: prev: { libcec = prev.libcec.override { withLibraspberrypi = true; }; })
    ];

    services.udev.extraRules = ''
      # allow access to raspi cec device for video group (and optionally register it as a systemd device, used below)
      KERNEL=="vchiq", GROUP="video", MODE="0660", TAG+="systemd", ENV{SYSTEMD_ALIAS}="/dev/vchiq"
    '';
  };
}
