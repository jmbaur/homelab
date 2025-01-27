{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    fileContents
    getExe
    mkEnableOption
    mkIf
    optionalString
    ;

  cfg = config.custom.ukiInstaller;
in
{
  options.custom.ukiInstaller.enable = mkEnableOption "UKI/systemd-boot/systemd-stub bootloader installer";

  config = mkIf cfg.enable {
    boot.bootspec.extensions."custom.ukify.v1" = {
      inherit (pkgs.stdenv.hostPlatform) efiArch;
      osRelease = config.environment.etc."os-release".source;
      stub = "${config.systemd.package}/lib/systemd/boot/efi/linux${pkgs.stdenv.hostPlatform.efiArch}.efi.stub";
      uname = config.system.build.kernel.version;
      devicetree =
        if (with config.hardware.deviceTree; enable && name != null) then
          "${config.hardware.deviceTree.package}/${config.hardware.deviceTree.name}"
        else
          null;
    };

    environment.systemPackages = [ pkgs.sbctl ];

    boot.loader.systemd-boot.enable = false;

    systemd.services.reset-loader-conf = {
      wantedBy = [ "default.target" ];
      unitConfig.ConditionDirectoryNotEmpty = "${config.boot.loader.efi.efiSysMountPoint}/loader/keys/auto";
      script = ''
        if [[ $(od --skip-bytes 4 --read-bytes 1 --output-duplicates --format dI --address-radix n /sys/firmware/efi/efivars/SecureBoot-8be4df61-93ca-11d2-aa0d-00e098032b8c) -eq 1 ]]; then
          rm -rf ${config.boot.loader.efi.efiSysMountPoint}/loader/keys
          sed -i '/secure-boot-enroll force/d' ${config.boot.loader.efi.efiSysMountPoint}/loader/loader.conf
        fi
      '';
    };

    systemd.services.fwupd = mkIf config.services.fwupd.enable {
      environment.FWUPD_EFIAPPDIR = "${config.boot.loader.efi.efiSysMountPoint}/EFI/nixos";
    };

    services.fwupd.uefiCapsuleSettings = mkIf config.services.fwupd.enable {
      DisableShimForSecureBoot = true;
    };

    boot.loader.external = {
      enable = true;
      installHook = getExe (
        pkgs.writeShellApplication {
          name = "uki-installer";
          runtimeInputs = [
            config.nix.package
            pkgs.coreutils-full
            pkgs.findutils
            pkgs.jq
            pkgs.sbctl
            pkgs.systemdUkify
          ];
          text = ''
            declare -r boot_loader_timeout=${toString config.boot.loader.timeout}
            declare -r can_touch_efi_variables=${toString config.boot.loader.efi.canTouchEfiVariables}
            declare -r efi_sys_mount_point=${config.boot.loader.efi.efiSysMountPoint}
            declare -r fwupd_efi=${optionalString config.services.fwupd.enable "${pkgs.fwupd-efi}/libexec/fwupd/efi/fwupd${pkgs.stdenv.hostPlatform.efiArch}.efi"}
            declare -r ukify_jq=${./ukify.jq}
            ${fileContents ./uki-installer.bash}
          '';
        }
      );
    };
  };
}
