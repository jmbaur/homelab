# The raspberry pi 4 doesn't have any storage medium other than the sd-card or
# usb, so we store u-boot and other firmware files on the sd-card and store the
# OS on a usb drive.

{
  dosfstools,
  lib,
  mtools,
  raspberrypi-armstubs,
  raspberrypifw,
  runCommand,
  uboot-rpi_4,
  util-linux,
  writeText,
}:

let
  firmwarePartitionID = "0x2178694e";
  firmwareSize = 128;

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

  uboot = uboot-rpi_4.override {
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
in
runCommand "rpi4-firmware-image"
  {
    nativeBuildInputs = [
      dosfstools
      mtools
      util-linux
    ];
    passthru = {
      inherit uboot;
    };
  }
  ''
    mkdir -p $out

    img=$out/firmware

    truncate -s $((${toString firmwareSize} * 512 * 1024)) $img

    sfdisk --no-reread --no-tell-kernel $img <<EOF
      label: dos
      label-id: ${firmwarePartitionID}
      size=$firmwareSizeBlocks, type=b
    EOF

    eval $(partx $img -o START,SECTORS --nr 1 --pairs)
    truncate -s $((SECTORS * 512)) fs.img
    mkfs.vfat --invariant -i ${firmwarePartitionID} -n FIRMWARE fs.img

    mkdir firmware
    cp ${uboot}/u-boot.bin firmware/kernel8.img
    cp ${configTxt} firmware/config.txt
    cp ${raspberrypi-armstubs}/armstub8-gic.bin firmware/armstub8-gic.bin
    cp ${raspberrypifw}/share/raspberrypi/boot/bcm2711-rpi-4-b.dtb firmware/bcm2711-rpi-4-b.dtb
    find ${raspberrypifw}/share/raspberrypi/boot \( -name "fixup*" -o -name "start*" \) \
      -exec sh -c 'cp {} firmware/$(basename {})' \;

    cd firmware
    for d in $(find . -type d -mindepth 1 | sort); do
      faketime "2000-01-01 00:00:00" mmd -i ../fs.img "::/$d"
    done
    for f in $(find . -type f | sort); do
      mcopy -pvm -i ../fs.img "$f" "::/$f"
    done
    cd ..

    fsck.vfat -vn fs.img
    dd conv=notrunc if=fs.img of=$img seek=$START count=$SECTORS

    xz -3 --compress --verbose --threads=$NIX_BUILD_CORES $img
  ''
