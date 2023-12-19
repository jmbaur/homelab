{ config, lib, pkgs, ... }:
let
  deps = with pkgs.buildPackages; lib.makeBinPath [ ubootTools dtc xz ];
  inherit (config.custom.fitImage) padToSize;
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
  };

  config = {
    system.build.fitImage = pkgs.runCommand "uImage" { } ''
      export PATH=${deps}:$PATH

      export description="${with config.system.nixos; "${distroName} ${codeName} ${version}"}"
      export arch=${pkgs.stdenv.hostPlatform.linuxArch}
      export linux_kernel=$PWD/kernel.lzma
      export initrd=${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile}

      lzma --threads 0 <${config.system.build.kernel}/${config.system.boot.loader.kernelFile} >$linux_kernel

      bash ${./make-fit-image-its.bash} ${config.hardware.deviceTree.package} >image.its

      mkimage -f image.its uImage
      ${lib.optionalString (padToSize != null) ''
      dd status=none bs=1K count=${toString (padToSize / 1024)} if=/dev/zero of=$out
      ''}
      dd status=none bs=1K conv=notrunc if=uImage of=$out
    '';
  };
}
