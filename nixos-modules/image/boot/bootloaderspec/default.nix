{ config, lib, pkgs, ... }:
let
  cfg = config.custom.image;

  inherit (config.system.nixos) distroId;

  loaderConf = pkgs.writeText "loader.conf" ''
    timeout ${if (config.boot.loader.timeout != null) then toString config.boot.loader.timeout else "menu-force"}
    editor yes
  '';

  entryConf = pkgs.writeText "entry.conf" (''
    title ${with config.system.nixos; "${distroName} ${codeName} ${release}"}
    version ${cfg.version}
    linux /EFI/${distroId}/linux_${cfg.version}
    initrd /EFI/${distroId}/initrd_${cfg.version}
  '' + lib.optionalString config.hardware.deviceTree.enable ''
    devicetree /EFI/${distroId}/devicetree_${cfg.version}.dtb
  '' + ''
    options init=${config.system.build.toplevel}/init usrhash=@usrhash@ ${toString config.boot.kernelParams}
    architecture ${pkgs.stdenv.hostPlatform.efiArch}
  '');
in
{
  config = lib.mkIf (cfg.enable && cfg.bootVariant == "bootloaderspec") {
    assertions = [{
      assertion = config.hardware.deviceTree.enable -> config.hardware.deviceTree.name != null;
      message = "need to specify config.hardware.deviceTree.name";
    }];

    systemd.sysupdate.transfers = {
      "70-boot-entry" = {
        Transfer.ProtectVersion = "%A";
        Source = {
          Type = "regular-file";
          Path = "/run/update";
          MatchPattern = "${distroId}_@v.conf";
        };
        Target = {
          Type = "regular-file";
          Path = "/loader/entries";
          PathRelativeTo = config.systemd.repart.partitions."10-boot".Type;
          MatchPattern = "${distroId}_@v+@l-@d.conf";
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
          Path = "/EFI/${distroId}";
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
          Path = "/EFI/${distroId}";
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
          Path = "/EFI/${distroId}";
          PathRelativeTo = config.systemd.repart.partitions."10-boot".Type;
          MatchPattern = "devicetree_@v.dtb";
          Mode = "0444";
          # Ensure that no more than 2 dtbs are present on the ESP at once.
          InstancesMax = 2;
        };
      };
    };

    custom.image = {
      bootFileCommands = ''
        echo "${loaderConf}:/loader/loader.conf" >> $bootfiles

        bootentry=$update/${distroId}_${cfg.version}.conf
        install -Dm0644 ${entryConf} $bootentry
        substituteInPlace $bootentry --subst-var usrhash

        ln -s ${config.system.build.kernel}/${config.system.boot.loader.kernelFile} $update/linux_${cfg.version}
        ln -s ${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile} $update/initrd_${cfg.version}

        echo "$bootentry:/loader/entries/${distroId}_${cfg.version}.conf" >> $bootfiles
        echo "$update/linux_${cfg.version}:/EFI/${distroId}/linux_${cfg.version}" >> $bootfiles
        echo "$update/initrd_${cfg.version}:/EFI/${distroId}/initrd_${cfg.version}" >> $bootfiles
      '' + lib.optionalString config.hardware.deviceTree.enable ''
        ln -s ${config.hardware.deviceTree.package}/${config.hardware.deviceTree.name} $update/devicetree_${cfg.version}.dtb
        echo "${config.hardware.deviceTree.package}/${config.hardware.deviceTree.name}:/EFI/${distroId}/devicetree_${cfg.version}.dtb" >> $bootfiles
      '';
    };
  };
}
