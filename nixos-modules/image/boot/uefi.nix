{ config, lib, pkgs, ... }:
let
  cfg = config.custom.image;

  systemdUkify = pkgs.buildPackages.systemdMinimal.override {
    withEfi = true;
    withUkify = true;
    withBootloader = true;
  };

  nixosUki = pkgs.runCommand "nixos-uki.efi" { } ''
    ${systemdUkify}/lib/systemd/ukify build \
      --linux=${config.system.build.kernel}/${config.system.boot.loader.kernelFile} \
      --cmdline="init=${config.system.build.toplevel}/init ${toString config.boot.kernelParams}" \
      --initrd=${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile} \
      --os-release=@${config.environment.etc."os-release".source} \
      --output=$out
  '';

  systemdBoot = "${config.systemd.package}/lib/systemd/boot/efi/systemd-boot${pkgs.stdenv.hostPlatform.efiArch}.efi";
in
{
  config = lib.mkIf (cfg.bootVariant == "uefi") {
    image.repart.partitions.boot = {
      contents = {
        "/EFI/BOOT/BOOT${lib.toUpper pkgs.stdenv.hostPlatform.efiArch}.EFI".source = systemdBoot;
        "/EFI/Linux/nixos${config.system.nixos.versionSuffix}.efi".source = nixosUki;
      };
      repartConfig = {
        Type = "esp";
        Label = "BOOT";
        Format = "vfat";
        SizeMinBytes = "256M";
        SizeMaxBytes = "256M";
      };
    };
  };
}
