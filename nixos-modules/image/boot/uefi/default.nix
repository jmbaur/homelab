{ config, lib, pkgs, ... }:
let
  cfg = config.custom.image;

  systemdUkify = pkgs.buildPackages.systemdMinimal.override {
    withEfi = true;
    withUkify = true;
    withBootloader = true;
  };

  loaderConf = pkgs.writeText "loader.conf" ''
    timeout 5
    editor yes
  '';

  systemdBoot = "${config.systemd.package}/lib/systemd/boot/efi/systemd-boot${pkgs.stdenv.hostPlatform.efiArch}.efi";
in
{
  config = lib.mkIf (cfg.bootVariant == "uefi") {
    custom.image.bootFileCommands = ''
      echo "${loaderConf}:/loader/loader.conf"
      echo "${systemdBoot}:/EFI/BOOT/BOOT${lib.toUpper pkgs.stdenv.hostPlatform.efiArch}.EFI" >> $bootfiles

      cmdline=("init=${config.system.build.toplevel}/init")
      cmdline+=("usrhash=$(jq --raw-output '.[] | select(.label=="usr-a") | .roothash' <$out/repart-output.json)")
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
        --output=$out/uki.efi

      echo "$out/uki.efi:/EFI/Linux/nixos${config.system.nixos.versionSuffix}.efi" >> $bootfiles
    '';
  };
}
