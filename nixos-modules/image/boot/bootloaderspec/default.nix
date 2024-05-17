{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.image;

  inherit (config.system.image) id version;

  loaderConf = pkgs.writeText "loader.conf" ''
    timeout ${
      if (config.boot.loader.timeout != null) then toString config.boot.loader.timeout else "menu-force"
    }
    editor yes
  '';

  entryConf = pkgs.writeText "entry.conf" (
    ''
      title ${with config.system.nixos; "${distroName} ${codeName} ${release}"}
      version ${version}
      linux /EFI/${id}/linux_${version}
      initrd /EFI/${id}/initrd_${version}
    ''
    + lib.optionalString config.hardware.deviceTree.enable ''
      devicetree /EFI/${id}/devicetree_${version}.dtb
    ''
    + ''
      options init=${config.system.build.toplevel}/init usrhash=@usrhash@ ${toString config.boot.kernelParams}
      architecture ${pkgs.stdenv.hostPlatform.efiArch}
    ''
  );
in
{
  config = lib.mkIf (cfg.enable && cfg.boot.bootLoaderSpec.enable or false) {
    assertions = [
      {
        assertion = config.hardware.deviceTree.enable -> config.hardware.deviceTree.name != null;
        message = "need to specify config.hardware.deviceTree.name";
      }
    ];

    systemd.sysupdate.transfers = {
      "70-boot-entry" = {
        Transfer.ProtectVersion = "%A";
        Source = {
          Type = "regular-file";
          Path = "/run/update";
          MatchPattern = "${id}_@v.conf";
        };
        Target = {
          Type = "regular-file";
          Path = "/loader/entries";
          PathRelativeTo = config.systemd.repart.partitions."10-boot".Type;
          # TODO(jared): We shouldn't have to use `toString` here
          MatchPattern = toString [
            "${id}_@v+@l-@d.conf"
            "${id}_@v+@l.conf"
            "${id}_@v.conf"
          ];
          Mode = "0444";
          TriesLeft = 3;
          TriesDone = 0;
          # Ensure that no more than 2 boot entries are present on the ESP at once.
          InstancesMax = 2;
        };
      };
      "70-linux" = {
        Transfer.ProtectVersion = "%A";
        Source = {
          Type = "regular-file";
          Path = "/run/update";
          MatchPattern = "linux_@v";
        };
        Target = {
          Type = "regular-file";
          Path = "/EFI/${id}";
          PathRelativeTo = config.systemd.repart.partitions."10-boot".Type;
          MatchPattern = "linux_@v";
          Mode = "0444";
          # Ensure that no more than 2 kernel images are present on the ESP at once.
          InstancesMax = 2;
        };
      };
      "70-initrd" = {
        Transfer.ProtectVersion = "%A";
        Source = {
          Type = "regular-file";
          Path = "/run/update";
          MatchPattern = "initrd_@v";
        };
        Target = {
          Type = "regular-file";
          Path = "/EFI/${id}";
          PathRelativeTo = config.systemd.repart.partitions."10-boot".Type;
          MatchPattern = "initrd_@v";
          Mode = "0444";
          # Ensure that no more than 2 initrds are present on the ESP at once.
          InstancesMax = 2;
        };
      };
      "70-devicetree" = lib.mkIf config.hardware.deviceTree.enable {
        Transfer.ProtectVersion = "%A";
        Source = {
          Type = "regular-file";
          Path = "/run/update";
          MatchPattern = "devicetree_@v.dtb";
        };
        Target = {
          Type = "regular-file";
          Path = "/EFI/${id}";
          PathRelativeTo = config.systemd.repart.partitions."10-boot".Type;
          MatchPattern = "devicetree_@v.dtb";
          Mode = "0444";
          # Ensure that no more than 2 dtbs are present on the ESP at once.
          InstancesMax = 2;
        };
      };
    };

    custom.image.bootFileCommands =
      ''
        echo "${loaderConf}:/loader/loader.conf" >>$bootfiles

        bootentry=$update/${id}_${version}+3-0.conf
        install -Dm0644 ${entryConf} $bootentry
        substituteInPlace $bootentry --subst-var usrhash

        linux=$update/linux_${version}
        initrd=$update/initrd_${version}
        ln -s ${config.system.build.kernel}/${config.system.boot.loader.kernelFile} $linux
        ln -s ${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile} $initrd

        echo "$bootentry:/loader/entries/$(basename $bootentry)" >>$bootfiles
        echo "$linux:/EFI/${id}/$(basename $linux)" >>$bootfiles
        echo "$initrd:/EFI/${id}/$(basename $initrd)" >>$bootfiles
      ''
      + lib.optionalString config.hardware.deviceTree.enable ''
        dtb=$update/devicetree_${version}.dtb
        ln -s ${config.hardware.deviceTree.package}/${config.hardware.deviceTree.name} $dtb
        echo "$dtb:/EFI/${id}/$(basename $dtb)" >>$bootfiles
      '';
  };
}
