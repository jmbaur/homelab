{ config, lib, pkgs, ... }:
let
  cfg = config.custom.image;

  systemdUkify = pkgs.buildPackages.systemdMinimal.override {
    withEfi = true;
    withUkify = true;
    withBootloader = true;
  };

  systemdBoot = "${config.systemd.package}/lib/systemd/boot/efi/systemd-boot${pkgs.stdenv.hostPlatform.efiArch}.efi";
in
{
  config = lib.mkIf (cfg.bootVariant == "uefi") {
    custom.image.bootFileCommands = ''
      echo "${systemdBoot}:/EFI/BOOT/BOOT${lib.toUpper pkgs.stdenv.hostPlatform.efiArch}.EFI"

      cmdline=("init=${config.system.build.toplevel}/init")
      cmdline+=("usrhash=$(jq --raw-output '.[] | select(.label=="usr-a") | .roothash' <$out/repart-output.json)")
      for param in ${toString config.boot.kernelParams}; do
        cmdline+=("$param")
      done

      # ukify does not output to stderr
      ${systemdUkify}/lib/systemd/ukify build \
        --no-sign-kernel \
        --linux=${config.system.build.kernel}/${config.system.boot.loader.kernelFile} \
        --cmdline="$(echo "''${cmdline[@]}")" \
        --initrd=${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile} \
        --os-release=@${config.environment.etc."os-release".source} \
        --output=$out/uki.efi \
        1>&2

      echo "$out/uki.efi:/EFI/Linux/nixos-${config.system.nixos.versionSuffix}.efi"
    '';
  };
}
