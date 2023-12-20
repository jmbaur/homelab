{ config, lib, pkgs, ... }:
let
  deps = with pkgs.buildPackages; lib.makeBinPath [ ubootTools dtc xz ];
  inherit (config.custom.fitImage) padToSize loadAddress;

  kernelPath = "${config.system.build.kernel}/${config.system.boot.loader.kernelFile}";

  bootScript = pkgs.writeText "boot.cmd" ''
    setenv bootargs "init=${config.system.build.toplevel}/init ${toString config.boot.kernelParams} ''${bootargs}"
    bootm $loadaddr
  '';
in
{
  options = with lib; {
    custom.fitImage.padToSize = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = mdDoc ''
        Total size that the image should be padded to
      '';
      example = literalExpression ''64 * 1024 * 1024''; # 64M
    };
    custom.fitImage.loadAddress = mkOption {
      type = types.str;
      default = "0x0";
    };
  };

  config = {
    system.build.fitImage = pkgs.runCommand "uImage" { } (''
      export PATH=${deps}:$PATH

      declare kernel_compression
      export description="${with config.system.nixos; "${distroName} ${codeName} ${version}"}"
      export arch=${pkgs.stdenv.hostPlatform.linuxArch}
      export linux_kernel=kernel
      export initrd=${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile}
      export bootscript=${bootScript}
      export load_address=${loadAddress}

    '' + {
      "Image" = ''
        kernel_compression=lzma
        lzma --threads 0 <${kernelPath} >$linux_kernel
      '';
      "zImage" = ''
        kernel_compression=none
        cp ${kernelPath} $linux_kernel
      '';
      "bzImage" = ''
        kernel_compression=none
        cp ${kernelPath} $linux_kernel
      '';
    }.${config.system.boot.loader.kernelFile} + ''
      export kernel_compression

      bash ${./make-fit-image-its.bash} ${config.hardware.deviceTree.package} >image.its

      mkimage -f image.its uImage
      ${lib.optionalString (padToSize != null) ''
      dd status=none bs=1K count=${toString (padToSize / 1024)} if=/dev/zero of=$out
      ''}
      dd status=none bs=1K conv=notrunc if=uImage of=$out
    '');
  };
}
