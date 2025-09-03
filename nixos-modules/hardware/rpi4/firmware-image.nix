# The raspberry pi 4 doesn't have any storage medium other than the sd-card or
# usb, so we store u-boot and other firmware files on the sd-card and store the
# OS on a usb drive.

{
  dosfstools,
  lib,
  makeUBoot,
  mtools,
  raspberrypi-armstubs,
  raspberrypifw,
  runCommand,
  util-linux,
  writeText,

  # TODO(jared): how should we go about updating this??
  #
  # U-Boot copies some properties from the FDT on the firmware partition (see https://github.com/u-boot/u-boot/blob/274dc5291cfbcb54cf54c337d2123adea075e299/board/raspberrypi/rpi/rpi.c#L554).
  # In order for us to get the proper set of changes we apply in hardware.deviceTree.overlays, we must use our own FDT.
  deviceTreeFile,
}:

let
  firmwarePartitionID = "0x2178694e";

  # Last I checked, all the RPI4 firmware we are using is about 23MiB, so using
  # 32MiB image size should give us enough space.
  firmwareSize = 32 * 1024 * 1024; # 32MiB

  configTxt = writeText "config.txt" ''
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

  kernelLoadAddress = 524288;
  bootmLen = 80 * 1024 * 1024; # 80MiB

  uboot = makeUBoot {
    boardName = "rpi_arm64";
    artifacts = [ "u-boot.bin" ];
    meta.platforms = [ "aarch64-linux" ];
    kconfig = with lib.kernel; {
      DISTRO_DEFAULTS = unset;
      BOOTSTD_DEFAULTS = yes;
      FIT = yes;

      # Allow for larger than the default 8MiB kernel size
      SYS_BOOTM_LEN = freeform "0x${lib.toHexString bootmLen}";
      SYS_LOAD_ADDR = freeform "0x${lib.toHexString (bootmLen + kernelLoadAddress)}";

      # We don't install OS to SD card, we install it to a SATA device that
      # will have a different FAT partition, so use that one for storing the
      # environment and allow for userspace changes using fw_setenv without
      # having to mount the FAT partition on the SD card.
      ENV_FAT_DEVICE_AND_PART = freeform "1:1";

      # Allow for using u-boot scripts.
      BOOTSTD_FULL = yes;

      BOOTCOUNT_LIMIT = yes;
      BOOTCOUNT_ENV = yes;
    };
  };

  label = "FIRMWARE";
in
runCommand "rpi4-firmware-image"
  {
    nativeBuildInputs = [
      dosfstools
      mtools
      util-linux
    ];
    passthru = { inherit uboot label; };
  }
  ''
    img=$(mktemp)

    truncate -s ${toString firmwareSize} $img

    sfdisk --no-reread --no-tell-kernel $img <<EOF
      label: dos
      label-id: ${firmwarePartitionID}
      type=b
    EOF

    eval $(partx $img -o START,SECTORS --nr 1 --pairs)
    truncate -s $((SECTORS * 512)) fs.img
    mkfs.vfat --invariant -i ${firmwarePartitionID} -n ${label} fs.img

    mkdir firmware
    cp ${uboot}/u-boot.bin firmware/kernel8.img
    cp ${configTxt} firmware/config.txt
    cp ${raspberrypi-armstubs}/armstub8-gic.bin firmware/armstub8-gic.bin
    cp ${deviceTreeFile} firmware/bcm2711-rpi-4-b.dtb
    find ${raspberrypifw}/share/raspberrypi/boot \( -name "fixup*" -o -name "start*" \) \
      -exec sh -c 'cp {} firmware/$(basename {})' \;

    pushd firmware
    for d in $(find . -type d -mindepth 1 | sort); do
      faketime "2000-01-01 00:00:00" mmd -i ../fs.img "::/$d"
    done
    for f in $(find . -type f | sort); do
      mcopy -pvm -i ../fs.img "$f" "::/$f"
    done
    popd

    fsck.vfat -vn fs.img
    dd conv=notrunc if=fs.img of=$img seek=$START count=$SECTORS

    xz -3 --compress --verbose --threads=$NIX_BUILD_CORES <$img >$out
  ''
