{ config, lib, pkgs, ... }:
let
  cfg = config.custom.image;

  inherit (config.system.image) id version;

  fixedFitImageName = "${id}_${version}.uImage";

  deviceTreeArgs = with config.hardware.deviceTree;
    lib.optionals enable
      ([ package ] ++ lib.optional (name != null) name);

  # depends on:
  # - CONFIG_CMD_SAVEENV
  # - $loadaddr being set
  # - fitimage containing an embedded script called "bootscript"
  globalBootScript = pkgs.writeText "boot.cmd" ''
    if test ! -n ''${version}; then
      env set version ${version}
      env set needs_saveenv 1
    fi

    if test ! -n ''${altversion}; then
      env set altversion ${version}
      env set needs_saveenv 1
    fi

    if test ! -n ''${altbootcmd}; then
      env set altbootcmd 'env set badversion ''${version}; env set version ''${altversion}; env set altversion ''${badversion}; env delete -f badversion; run bootcmd'
      env set needs_saveenv 1
    fi

    if env exists needs_saveenv; then
      env delete -f needs_saveenv
      saveenv
    fi

    load ${cfg.uboot.bootMedium.type} ${toString cfg.uboot.bootMedium.index}:1 $loadaddr "${id}_''${version}.uImage"
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
  options.custom.image.uboot = with lib; {
    enable = mkEnableOption "TODO";

    kernelLoadAddress = mkOption {
      type = types.str;
      description = mdDoc ''
        TODO
      '';
    };

    bootMedium = {
      type = mkOption {
        type = types.enum [ "mmc" "scsi" "nvme" "usb" "virtio" ];
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

  config = lib.mkIf (cfg.enable && cfg.uboot.enable) {
    system.build.bootscr = globalBootScriptImage;
    # TODO(jared): need to add a non-UEFI equivalent to systemd-bless-boot
    systemd.additionalUpstreamSystemUnits = [ /*"systemd-bless-boot.service"*/ ];

    systemd.sysupdate.transfers."70-fit-image" = {
      Transfer.ProtectVersion = "%A";
      Source = {
        Type = "regular-file";
        Path = "/run/update";
        MatchPattern = "${id}_@v.uImage";
      };
      Target = {
        Type = "regular-file";
        Path = "/";
        PathRelativeTo = config.systemd.repart.partitions."10-boot".Type;
        MatchPattern = "${id}_@v.uImage";
        Mode = "0444";
        # Ensure that no more than 2 FIT images are present on the ESP at once.
        InstancesMax = 2;
      };
    };

    custom.image.bootFileCommands = ''
      declare kernel_compression
      declare x86_setup_code # unused on non-x86 systems
      export description="${with config.system.nixos; "${distroName} ${codeName} ${release}"}"
      export arch=${pkgs.stdenv.hostPlatform.linuxArch}
      export linux_kernel=kernel
      export initrd=${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile}
      export bootscript=bootscript
      export load_address=${cfg.uboot.kernelLoadAddress}

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

      bash ${./make-fit-image-its.bash} ${toString deviceTreeArgs} >image.its

      mkimage --fit image.its "$update/${fixedFitImageName}"

      ln -sf ${globalBootScriptImage} $update/boot.scr

      echo "$update/boot.scr:/boot.scr" >> $bootfiles
      echo "$update/${fixedFitImageName}:/${fixedFitImageName}" >> $bootfiles
    '';
  };
}
