{
  config,
  lib,
  pkgs,
  ...
}:

let
  kernelLoadAddress = 524288;
  bootmLen = 80 * 1024 * 1024; # 80MiB

  uboot = pkgs.uboot-rpi_4.override {
    extraStructuredConfig = with lib.kernel; {
      DISTRO_DEFAULTS = unset;
      BOOTSTD_DEFAULTS = yes;
      FIT = yes;

      # Allow for larger than the default 8MiB kernel size
      SYS_BOOTM_LEN = freeform "0x${lib.toHexString bootmLen}";
      SYS_LOAD_ADDR = freeform "0x${lib.toHexString (bootmLen + kernelLoadAddress)}";

      # Allow for using u-boot scripts.
      BOOTSTD_FULL = yes;

      BOOTCOUNT_LIMIT = yes;
      BOOTCOUNT_ENV = yes;
    };
  };

  configTxt = pkgs.writeText "config.txt" ''
    [all]
    arm_64bit=1
    arm_boost=1
    armstub=armstub8-gic.bin
    avoid_warnings=1
    disable_overscan=1
    enable_gic=1
    enable_uart=1
    kernel=kernel8.img
  '';
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

    system.build.rpiSupportFiles = pkgs.runCommand "rpi-support-files" { } ''
      echo ${config.system.build.firmware}/u-boot.bin:/kernel8.img >> $out
      echo ${configTxt}:/config.txt >> $out
      echo ${pkgs.raspberrypi-armstubs}/armstub8-gic.bin:/armstub8-gic.bin >> $out
      echo ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2711-rpi-4-b.dtb:/bcm2711-rpi-4-b.dtb >> $out
      find ${pkgs.raspberrypifw}/share/raspberrypi/boot -name "fixup*" \
        -exec sh -c 'echo {}:/$(basename {})' \; >> $out
      find ${pkgs.raspberrypifw}/share/raspberrypi/boot -name "start*" \
        -exec sh -c 'echo {}:/$(basename {})' \; >> $out
    '';

    custom.image = {
      bootFileCommands = ''
        cat ${config.system.build.rpiSupportFiles} >> $bootfiles
      '';
      postImageCommands = ''
        # Modify the protective MBR to expose the EFI system partition on the MBR table
        ${lib.getExe' pkgs.buildPackages.gptfdisk "sgdisk"} --hybrid=1:EE $out/image.raw
        # Change the partition type of the EFI system partition on the MBR table to type 0xb (https://en.wikipedia.org/wiki/Partition_type#PID_0Bh).
        printf '\x0b' | dd status=none of=$out/image.raw bs=1 seek=$((0x1c2)) count=1 conv=notrunc
      '';
    };

    system.build.firmware = uboot;

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
