{ config, lib, pkgs, ... }:
let
  cfg = config.custom.image;

  inherit (config.system.nixos) distroId;

  systemdArchitecture = builtins.replaceStrings [ "_" ] [ "-" ] pkgs.stdenv.hostPlatform.linuxArch;

  systemdUkify = pkgs.buildPackages.systemdMinimal.override {
    withEfi = true;
    withUkify = true;
    withBootloader = true;
  };

  loaderConf = pkgs.writeText "loader.conf" ''
    timeout ${if (config.boot.loader.timeout != null) then toString config.boot.loader.timeout else "menu-force"}
    editor yes
  '';

  systemdBoot = "${config.systemd.package}/lib/systemd/boot/efi/systemd-boot${pkgs.stdenv.hostPlatform.efiArch}.efi";
in
{
  config = lib.mkIf (cfg.enable && cfg.bootVariant == "uefi") {
    assertions = [{
      assertion = config.hardware.deviceTree.enable -> config.hardware.deviceTree.name != null;
      message = "need to specify config.hardware.deviceTree.name";
    }];

    systemd.additionalUpstreamSystemUnits = [ "systemd-bless-boot.service" ];

    systemd.sysupdate.transfers."70-uki" = {
      Transfer.ProtectVersion = "%A";
      Source = {
        Type = "regular-file";
        Path = "/run/update";
        MatchPattern = "${distroId}_@v.efi";
      };
      Target = {
        Type = "regular-file";
        Path = "/EFI/Linux";
        PathRelativeTo = config.systemd.repart.partitions."10-boot".Type;
        MatchPattern = "${distroId}_@v+@l-@d.efi";
        Mode = "0444";
        TriesLeft = 3;
        TriesDone = 0;
        # Ensure that no more than 2 UKIs are present on the ESP at once.
        InstancesMax = 2;
      };
    };

    custom.image = {
      bootFileCommands = ''
        echo "${loaderConf}:/loader/loader.conf" >> $bootfiles
        echo "${systemdBoot}:/EFI/BOOT/BOOT${lib.toUpper pkgs.stdenv.hostPlatform.efiArch}.EFI" >> $bootfiles

        cmdline=("init=${config.system.build.toplevel}/init")
        cmdline+=("usrhash=$(jq --raw-output '.[] | select(.type == "usr-${systemdArchitecture}") | .roothash' <$out/repart-output.json)")
        for param in ${toString config.boot.kernelParams}; do
          cmdline+=("$param")
        done

        ${systemdUkify}/lib/systemd/ukify build \
          --no-sign-kernel \
          --efi-arch=${pkgs.stdenv.hostPlatform.efiArch} \
          --uname=${config.system.build.kernel.version} \
          --stub=${config.systemd.package}/lib/systemd/boot/efi/linux${pkgs.stdenv.hostPlatform.efiArch}.efi.stub \
          --linux=${config.system.build.kernel}/${config.system.boot.loader.kernelFile} \
          --cmdline="$(echo "''${cmdline[@]}")" \
          --initrd=${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile} \
          --os-release=@${config.environment.etc."os-release".source} \
          ${lib.optionalString config.hardware.deviceTree.enable
            "--devicetree=${config.hardware.deviceTree.package}/${config.hardware.deviceTree.name}"} \
          --output=$update/${distroId}_${toString cfg.version}.efi

        echo "$update/${distroId}_${toString cfg.version}.efi:/EFI/Linux/${distroId}_${toString cfg.version}.efi" >> $bootfiles
      '';
    };
  };
}
