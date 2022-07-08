{ config, pkgs, lib, ... }:
let
  cfg = config.hardware.lx2k;
in
{
  options.hardware.lx2k.enable = lib.mkEnableOption "hardware support for the Honeycomb LX2K board";
  config = lib.mkIf cfg.enable {
    boot.kernelParams = [
      "console=ttyAMA0,115200"
      "arm-smmu.disable_bypass=0"
      "iommu.passthrough=1"
    ];
    boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_5_18;

    # Setup SFP+ network interfaces early so systemd can pick everything up.
    boot.initrd.extraUtilsCommands = ''
      copy_bin_and_libs ${pkgs.restool}/bin/restool
      copy_bin_and_libs ${pkgs.restool}/bin/ls-main
      copy_bin_and_libs ${pkgs.restool}/bin/ls-addni
      # Patch paths
      sed -i "1i #!$out/bin/sh" $out/bin/ls-main
    '';
    boot.initrd.postDeviceCommands = ''
      ls-addni dpmac.7
      ls-addni dpmac.8
      ls-addni dpmac.9
      ls-addni dpmac.10
    '';
  };
}
