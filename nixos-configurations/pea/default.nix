{
  config,
  pkgs,
  ...
}:

{
  hardware.chromebook.asurada-spherion.enable = true;

  system.build.testImage = pkgs.callPackage (
    {
      dtc,
      runCommand,
      ubootTools,
      util-linux,
      vboot_reference,
      xz,
      zstd,
    }:

    runCommand "test-image"
      {
        nativeBuildInputs = [
          dtc
          ubootTools
          util-linux
          vboot_reference
          xz
          zstd
        ];
      }
      ''
        lzma --threads $NIX_BUILD_CORES <${config.system.build.kernel}/${config.system.boot.loader.kernelFile} >kernel.lzma
        cp ${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile} initrd
        cp ${config.hardware.deviceTree.package}/${config.hardware.deviceTree.name} fdt

        cp ${./fitimage.its} fitimage.its # needs to be in the same directory
        mkimage -D "-I dts -O dtb -p 2048" -f fitimage.its vmlinux.uimg

        dd if=/dev/zero of=bootloader.bin bs=512 count=1

        echo "init=${config.system.build.toplevel}/init ${toString config.boot.kernelParams}" >kernel-params

        futility vbutil_kernel \
          --pack kpart \
          --version 1 \
          --vmlinuz vmlinux.uimg \
          --arch aarch64 \
          --keyblock ${vboot_reference}/share/vboot/devkeys/kernel.keyblock \
          --signprivate ${vboot_reference}/share/vboot/devkeys/kernel_data_key.vbprivk \
          --config kernel-params \
          --bootloader bootloader.bin

        dd if=/dev/zero of=image bs=4M count=20
        sfdisk --no-reread --no-tell-kernel image <<EOF
            label: gpt
            label-id: A8ABB0FA-2FD7-4FB8-ABB0-2EEB7CD66AFA
            size=64m, type=FE3A2A5D-4F32-41A7-B725-ACCC3285A309, uuid=534078AF-3BB4-EC43-B6C7-828FB9A788C6, name=kernel
        EOF
        cgpt add -i 1 -S 1 -T 5 -P 10 image
        eval "$(partx image -o START,SECTORS --nr 1 --pairs)"
        dd conv=notrunc if=kpart of=image seek="$START" count="$SECTORS"
        zstd -T$NIX_BUILD_CORES -o $out image
      ''
  ) { };
}
