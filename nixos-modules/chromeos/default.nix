# NOTE: This module is not meant to be a long-term support for chromeos
# devices, just a stop-gap measure for getting nixos up and running on
# chromeos devices. A better long-term solution is to replace the on-board
# firmware with something capable of booting

{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    getExe'
    makeBinPath
    mkEnableOption
    mkIf
    ;

  cfg = config.custom.dont-use-me-chromeos-partition;

  extraInstallCommands = ''
    ${getExe' pkgs.coreutils-full "dd"} bs=4M if=$1/kpart of=/dev/disk/by-partlabel/kernel
  '';
in
{
  options.custom.dont-use-me-chromeos-partition.enable = mkEnableOption "chromeos partition support";

  config = mkIf cfg.enable {
    system.extraSystemBuilderCmds = ''
      export PATH=$PATH:${
        makeBinPath (
          with pkgs.buildPackages;
          [
            dtc
            ubootTools
            vboot_reference
            xz
          ]
        )
      }

      lzma --threads $NIX_BUILD_CORES <${config.system.build.kernel}/${config.system.boot.loader.kernelFile} >kernel.lzma
      cp ${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile} initrd
      cp ${config.hardware.deviceTree.package}/${config.hardware.deviceTree.name} fdt

      cp ${./fitimage.its} fitimage.its # needs to be in the same directory
      mkimage -D "-I dts -O dtb -p 2048" -f fitimage.its vmlinux.uimg

      dd status=none if=/dev/zero of=bootloader.bin bs=512 count=1

      echo "init=$out/init ${toString config.boot.kernelParams}" >kernel-params

      futility vbutil_kernel \
        --pack $out/kpart \
        --version 1 \
        --vmlinuz vmlinux.uimg \
        --arch aarch64 \
        --keyblock ${pkgs.vboot_reference}/share/vboot/devkeys/kernel.keyblock \
        --signprivate ${pkgs.vboot_reference}/share/vboot/devkeys/kernel_data_key.vbprivk \
        --config kernel-params \
        --bootloader bootloader.bin
    '';

    system.build.testImage = pkgs.callPackage (
      {
        runCommand,
        util-linux,
        vboot_reference,
        zstd,
      }:

      runCommand "test-image"
        {
          nativeBuildInputs = [
            util-linux
            vboot_reference
            zstd
          ];
        }
        ''
          mkdir -p $out

          dd if=/dev/zero of=$out/image bs=4M count=20
          sfdisk --no-reread --no-tell-kernel $out/image <<EOF
              label: gpt
              label-id: A8ABB0FA-2FD7-4FB8-ABB0-2EEB7CD66AFA
              size=64m, type=FE3A2A5D-4F32-41A7-B725-ACCC3285A309, uuid=534078AF-3BB4-EC43-B6C7-828FB9A788C6, name=kernel
          EOF
          cgpt add -i 1 -S 1 -T 5 -P 10 $out/image
          eval "$(partx $out/image -o START,SECTORS --nr 1 --pairs)"
          dd conv=notrunc if=${config.system.build.toplevel}/kpart of=$out/image seek="$START" count="$SECTORS"
          zstd -T$NIX_BUILD_CORES --rm $out/image
        ''
    ) { };

    boot.loader.grub = { inherit extraInstallCommands; };
    boot.loader.systemd-boot = { inherit extraInstallCommands; };
    boot.loader.tinyboot = { inherit extraInstallCommands; };
  };
}
