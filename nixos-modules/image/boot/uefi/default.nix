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

  systemdBoot = "${config.systemd.package}/lib/systemd/boot/efi/systemd-boot${pkgs.stdenv.hostPlatform.efiArch}.efi";
in
{
  config = lib.mkIf (cfg.enable && cfg.boot.uefi.enable or false) {
    assertions = [
      {
        assertion = config.hardware.deviceTree.enable -> config.hardware.deviceTree.name != null;
        message = "need to specify config.hardware.deviceTree.name";
      }
    ];

    systemd.additionalUpstreamSystemUnits = [ "systemd-bless-boot.service" ];

    systemd.sysupdate.transfers."70-uki" = {
      Transfer.ProtectVersion = "%A";
      Source = {
        Type = "url-file";
        Path = cfg.update.source;
        MatchPattern = "${id}_@v.efi";
      };
      Target = {
        Type = "regular-file";
        Path = "/EFI/Linux";
        PathRelativeTo = config.systemd.repart.partitions."10-boot".Type;
        MatchPattern = [
          "${id}_@v+@l-@d.efi"
          "${id}_@v+@l.efi"
          "${id}_@v.efi"
        ];
        Mode = "0444";
        TriesLeft = 3;
        TriesDone = 0;
        # Ensure that no more than 2 UKIs are present on the ESP at once.
        InstancesMax = 2;
      };
    };

    custom.image.bootFileCommands = ''
      uki=$out/${id}_${version}.efi
      ukify build \
        --no-sign-kernel \
        --efi-arch=${pkgs.stdenv.hostPlatform.efiArch} \
        --uname=${config.system.build.kernel.version} \
        --stub=${config.systemd.package}/lib/systemd/boot/efi/linux${pkgs.stdenv.hostPlatform.efiArch}.efi.stub \
        --linux=${config.system.build.kernel}/${config.system.boot.loader.kernelFile} \
        --cmdline="init=${config.system.build.toplevel}/init usrhash=$usrhash ${toString config.boot.kernelParams}" \
        --initrd=${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile} \
        --os-release=@${config.environment.etc."os-release".source} \
        ${lib.optionalString config.hardware.deviceTree.enable "--devicetree=${config.hardware.deviceTree.package}/${config.hardware.deviceTree.name}"} \
        --output="$uki"
      echo "$uki:/EFI/Linux/$(basename $uki | sed 's,\.efi,,')+3-0.efi" >>$bootfiles

      echo "${loaderConf}:/loader/loader.conf" >>$bootfiles
      echo "${systemdBoot}:/EFI/boot/boot${pkgs.stdenv.hostPlatform.efiArch}.efi" >>$bootfiles
    '';
  };
}
