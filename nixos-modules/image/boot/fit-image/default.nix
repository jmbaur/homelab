{ config, lib, pkgs, ... }:
let
  cfg = config.custom.image;

  inherit (config.system.nixos) distroId;

  fixedFitImageName = "${distroId}_${cfg.version}.uImage";

  # depends on:
  # - CONFIG_CMD_SAVEENV
  # - $loadaddr being set
  # - fitimage containing an embedded script called "bootscript"
  globalBootScript = pkgs.writeText "boot.cmd" ''
    if test ! env exists version; then env set version ${cfg.version} fi
    if test ! env exists altversion; then env set altversion ${cfg.version} fi

    if test ! altbootcmd; then
      env set altbootcmd 'env set badversion ''${version}; env set version ''${altversion}; env set altversion ''${badversion}; env delete -f badversion; run bootcmd'
      saveenv
    fi

    load ${cfg.ubootBootMedium.type} ${toString cfg.ubootBootMedium.index}:1 $loadaddr "${distroId}_''${version}.uImage"
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
    setenv bootargs "init=${config.system.build.toplevel}/init usrhash=@usrhash@ ${toString config.boot.kernelParams}"
    bootm $loadaddr
  '';
in
{
  options = with lib; {
    custom.image = {
      ubootLoadAddress = mkOption {
        type = types.str;
        description = mdDoc ''
          TODO
        '';
      };

      ubootBootMedium = {
        type = mkOption {
          type = types.enum [ "mmc" "nvme" "usb" "virtio" ];
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

  config = lib.mkIf (cfg.enable && cfg.bootVariant == "fit-image") {
    # TODO(jared): need to add a non-UEFI equivalent to systemd-bless-boot
    systemd.additionalUpstreamSystemUnits = [ /*"systemd-bless-boot.service"*/ ];

    systemd.sysupdate.transfers."70-fit-image" = {
      Transfer.ProtectVersion = "%A";
      Source = {
        Type = "regular-file";
        Path = "/run/update";
        MatchPattern = "${distroId}_@v.uImage";
      };
      Target = {
        Type = "regular-file";
        Path = "/";
        PathRelativeTo = config.systemd.repart.partitions."10-boot".Type;
        MatchPattern = "${distroId}_@v.uImage";
        Mode = "0444";
        # Ensure that no more than 2 FIT images are present on the ESP at once.
        InstancesMax = 2;
      };
    };

    custom.image.bootFileCommands = ''
      declare kernel_compression
      declare x86_setup_code # unused on non-x86 systems
      export description="${with config.system.nixos; "${distroName} ${codeName} ${cfg.version}"}"
      export arch=${pkgs.stdenv.hostPlatform.linuxArch}
      export linux_kernel=kernel
      export initrd=${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile}
      export bootscript=bootscript
      export load_address=${cfg.ubootLoadAddress}

      install -Dm0644 ${bootScript} $bootscript
      substituteInPlace $bootscript --subst-var usrhash

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
        kernel_compression=lzma
        tmp=$(mktemp)
        objcopy -O binary ${lib.getDev config.system.build.kernel}/vmlinux $tmp
        du -sh $tmp
        exit 3
        lzma --threads 0 <$tmp >$linux_kernel

        # The bzImage is (in simplified form) a concatenation of some setup
        # code (setup.bin) with a compressed vmlinux. The setup.bin _should_ be
        # within the first 17KiB of the bzImage, so we take the first 17KiB.
        #
        # TODO(jared): we should be smarter about only extracting what is
        # needed here.
        x86_setup_code=$(mktemp)
        dd bs=1K count=17 if=${kernelPath} of=$x86_setup_code
        export x86_setup_code
      '';
    }.${config.system.boot.loader.kernelFile} + ''
      export kernel_compression

      bash ${./make-fit-image-its.bash} ${with config.hardware.deviceTree; lib.optionalString enable package} >image.its

      mkimage --fit image.its "''${out}/${fixedFitImageName}"

      echo "${globalBootScriptImage}:/boot.scr" >> $bootfiles
      echo "''${out}/${fixedFitImageName}:/${fixedFitImageName}" >> $bootfiles
    '';
  };
}
