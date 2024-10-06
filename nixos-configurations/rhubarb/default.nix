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
  config = lib.mkMerge [
    {
      nixpkgs.hostPlatform = "aarch64-linux";

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

      # https://forums.raspberrypi.com/viewtopic.php?t=319435
      # systemd.repart.partitions."10-boot".Type = lib.mkForce "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7";

      system.build.firmware = uboot;

      hardware.deviceTree.enable = true;
      hardware.deviceTree.name = "broadcom/bcm2711-rpi-4-b.dtb";

      boot.kernelParams = [ "console=ttyS1,115200" ];

      environment.etc."fw_env.config".text = ''
        ${config.boot.loader.efi.efiSysMountPoint}/uboot.env 0x0000 0x10000
      '';

      environment.systemPackages = [ pkgs.uboot-env-tools ];
    }
    {
      custom.server.enable = true;
      custom.basicNetwork.enable = true;
      custom.nativeBuild = true;
      custom.image = {
        installer.targetDisk = "/dev/mmcblk0";
        boot.uboot = {
          enable = true;
          bootMedium.type = "mmc";
          kernelLoadAddress = "0x${lib.toHexString kernelLoadAddress}";
        };
      };
    }
    {
      services.xserver.desktopManager.kodi = {
        enable = true;
        package = pkgs.kodi.override {
          sambaSupport = false; # deps don't cross-compile
          x11Support = false;
          waylandSupport = true;
          pipewireSupport = true;
        };
      };
    }
  ];
}
