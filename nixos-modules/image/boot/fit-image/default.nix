{ config, lib, pkgs, ... }:
let
  cfg = config.custom.image;

  globalBootScript = pkgs.writeText "boot.cmd" ''
    if test -z $active; then
      setenv active a;
      saveenv
      echo no active partition set, using partition A
    fi

    setenv bootargs nixos.active=nixos-$active
    load ${cfg.ubootBootMedium.type} ${toString cfg.ubootBootMedium.index}:1 $loadaddr uImage.$active
    source ''${loadaddr}:bootscript
  '';

  globalBootScriptImage = pkgs.runCommand "boot.scr" { } ''
    ${lib.getExe' pkgs.buildPackages.ubootTools "mkimage"} \
      -A ${pkgs.stdenv.hostPlatform.linuxArch} \
      -O linux \
      -T script \
      -C none \
      -d ${globalBootScript} \
      $out
  '';

  kernelPath = "${config.system.build.kernel}/${config.system.boot.loader.kernelFile}";

  bootScript = pkgs.writeText "boot.cmd" ''
    setenv bootargs "init=${config.system.build.toplevel}/init ${toString config.boot.kernelParams} usrhash=@usrhash@ ''${bootargs}"
    bootm $loadaddr
  '';
in
{
  options = with lib; {
    custom.image = {
      ubootLoadAddress = mkOption {
        type = types.str;
        default = "0x0";
        description = mdDoc ''
          TODO
        '';
      };

      ubootBootMedium = {
        type = mkOption {
          type = types.enum [ "mmc" "nvme" "usb" ];
          description = mdDoc ''
            TODO
          '';
        };
        index = mkOption {
          type = types.int;
          default = 0;
          description = mdDoc ''
            TODO
          '';
        };
      };
    };
  };

  config = lib.mkIf (cfg.bootVariant == "fit-image") {
    custom.image.bootFileCommands = ''
      (
        declare kernel_compression
        export description="${with config.system.nixos; "${distroName} ${codeName} ${version}"}"
        export arch=${pkgs.stdenv.hostPlatform.linuxArch}
        export linux_kernel=kernel
        export initrd=${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile}
        export bootscript=bootscript
        export load_address=${cfg.ubootLoadAddress}

        install -Dm0644 ${bootScript} $bootscript
        substituteInPlace $bootscript \
          --replace '@usrhash@' $(jq --raw-output '.[] | select(.label=="usr-a") | .roothash' <$out/repart-output.json)

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

        mkimage -f image.its $out/uImage

        echo "${globalBootScriptImage}:/boot.scr"
        echo "$out/uImage:/uImage.a"
      )
    '';
  };
}
