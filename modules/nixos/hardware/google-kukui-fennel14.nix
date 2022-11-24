{ config, lib, pkgs, ... }:
with lib;
{
  options.hardware.kukui-fennel14 = {
    enable = mkEnableOption "google kukui-fennel14 board";
  };
  config = mkIf config.hardware.kukui-fennel14.enable {
    custom.laptop.enable = true;
    services.xserver.xkbOptions = "ctrl:swap_lwin_lctl";

    hardware.enableRedistributableFirmware = true;
    hardware.deviceTree = {
      enable = true;
      filter = "mt8183-kukui-jacuzzi-fennel14.dtb";
    };

    boot.initrd.availableKernelModules = [
      "ath10k_pci"
      "cros_ec"
      "cros_ec_keyb"
      "cros_ec_lid_angle"
      "cros_ec_rpmsg"
      "cros_ec_sensorhub"
      "cros_ec_sensors_core"
      "cros_ec_typec"
      "cros_usbpd_charger"
      "drm"
      "mediatek_drm"
      "mtk_rpmsg"
      "mtk_scp"
      "mtk_scp_ipi"
    ];

    boot.kernelPackages =
      let
        linux_chromeos_5-15 = { fetchgit, buildLinux, ... } @ args:
          buildLinux (args // rec {
            version = "5.15.79";
            modDirVersion = version;

            src = fetchgit {
              url = "https://chromium.googlesource.com/chromiumos/third_party/kernel/";
              rev = "c50a6bca527bfc29746bb0f9c20ceaf3aa4a9fd1";
              sha256 = "sha256-6pPQGVbaGyZsM/j051dYssofRhQZowcH5yLfL/3N2oE=";
            };
            kernelPatches = [ ];

            extraConfig = lib.replaceStrings
              [ "CONFIG_" "=" ] [ "" " " ]
              ''
                CONFIG_ATH10K=m
                CONFIG_ATH10K_DEBUG=y
                CONFIG_ATH10K_DEBUGFS=y
                CONFIG_SND_SOC=y
                CONFIG_SND_SOC_MT8173=y
                CONFIG_SND_SOC_MT8173_RT5650=y
                CONFIG_SND_SOC_MT8173_RT5650_RT5514=y
                CONFIG_SND_SOC_MT8173_RT5650_RT5676=y
                CONFIG_SND_SOC_MT8183=y
                CONFIG_SND_SOC_MT8183_DA7219_MAX98357A=y
                CONFIG_SND_SOC_MT8183_MT6358_TS3A227E_MAX98357A=y
                CONFIG_SND_SOC_MT8186=y
                CONFIG_SND_SOC_MT8186_MT6366_DA7219_MAX98357=y
                CONFIG_SND_SOC_MT8186_MT6366_RT1019_RT5682S=y
                CONFIG_SND_SOC_MT8192=y
                CONFIG_SND_SOC_MT8192_MT6359_RT1015_RT5682=y
                CONFIG_SND_SOC_SOF_MT8186=m
                CONFIG_SND_SOC_SOF_MTK_TOPLEVEL=y
                CONFIG_SND_SOC_SOF_OF=y
                CONFIG_SND_SOC_SOF_TOPLEVEL=y
                CONFIG_VIDEO_DW9768=m
                CONFIG_VIDEO_MEDIATEK_JPEG=m
                CONFIG_VIDEO_MEDIATEK_MDP=m
                CONFIG_VIDEO_MEDIATEK_MDP3=m
                CONFIG_VIDEO_MEDIATEK_VCODEC=m
                CONFIG_VIDEO_MEDIATEK_VPU=y
                CONFIG_VIDEO_OV02A10=m
                CONFIG_VIDEO_OV5695=m
                CONFIG_VIDEO_OV8856=m
              '';

            extraMeta.branch = "chromeos-5.15";
          } // (args.argsOverride or { }));
      in
      pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor (pkgs.callPackage linux_chromeos_5-15 { }));
  };
}
