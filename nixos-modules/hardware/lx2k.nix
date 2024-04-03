{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  options.hardware.lx2k = {
    enable = mkEnableOption "layerscape lx2k";
  };
  config = mkIf config.hardware.lx2k.enable {
    boot.kernelParams = [
      "radeon.si_support=0"
      "amdgpu.si_support=1"
      "console=ttyAMA0,115200"
      "arm-smmu.disable_bypass=0"
      "iommu.passthrough=1"
      "amdgpu.pcie_gen_cap=0x4"
      "usbcore.autosuspend=-1"
      "compat_uts_machine=armv7l"
    ];

    boot.kernelModules = [ "amc6821" ];

    boot.kernelPackages = pkgs.linuxPackages_6_1;

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

    boot.kernelPatches = [
      rec {
        name = "compat_uts_machine";
        patch = pkgs.fetchpatch {
          inherit name;
          url = "https://git.launchpad.net/~ubuntu-kernel/ubuntu/+source/linux/+git/jammy/patch/?id=c1da50fa6eddad313360249cadcd4905ac9f82ea";
          sha256 = "sha256-mpq4YLhobWGs+TRKjIjoe5uDiYLVlimqWUCBGFH/zzU=";
        };
      }
    ];
    nix.settings.extra-platforms = "armv7l-linux";
  };
}
