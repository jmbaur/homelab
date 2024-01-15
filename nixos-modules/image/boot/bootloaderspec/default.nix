{ config, lib, pkgs, ... }:
let
  cfg = config.custom.image;

  inherit (config.system.nixos) distroId;

  loaderConf = pkgs.writeText "loader.conf" ''
    timeout ${if (config.boot.loader.timeout != null) then toString config.boot.loader.timeout else "menu-force"}
    editor yes
  '';

  entryConf = pkgs.writeText "entry.conf" ''
    title ${with config.system.nixos; "${distroName} ${codeName} ${cfg.version}"}
    linux /EFI/${distroId}/linux_${cfg.version}
    initrd /EFI/${distroId}/initrd_${cfg.version}
    options init=${config.system.build.toplevel}/init usrhash=@usrhash@ ${toString config.boot.kernelParams}
  '';
in
{
  config = lib.mkIf (cfg.enable && cfg.bootVariant == "bootloaderspec") {
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
          MatchPattern = "${distroId}_@v.conf";
          Mode = "0444";
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
      '';
    };
  };
}
