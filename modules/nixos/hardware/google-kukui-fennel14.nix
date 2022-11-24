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
      "ath"
      "ath10k_core"
      "ath10k_pci"
      "ath10k_sdio"
      "cros_ec_lid_angle"
      "cros_ec_rpmsg"
      "cros_ec_sensorhub"
      "cros_ec_sensors_core"
      "cros_ec_typec"
      "drm"
      "mtk_rpmsg"
      "mtk_scp"
      "mtk_scp_ipi"
    ];

    boot.kernelPackages = pkgs.linuxPackages_latest;
    boot.kernelPatches = [{
      name = "chromeos-5.15-mediatek";
      patch = null;
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
      # CONFIG_DRM_ANALOGIX_ANX7625=y
      # CONFIG_DRM_ANALOGIX_ANX78XX=y
      # CONFIG_DRM_ITE_IT6505=y
      # CONFIG_DRM_MEDIATEK=y
      # CONFIG_DRM_MEDIATEK_HDMI=y
      # CONFIG_DRM_PANEL_BOE_TV101WUM_NL6=y
      # CONFIG_DRM_PANEL_INNOLUX_HIMAX8279D=y
      # CONFIG_DRM_PANEL_INNOLUX_P079ZCA=y
      # CONFIG_DRM_PANFROST=y
      # CONFIG_DRM_PARADE_PS8640=y
      # CONFIG_DRM_POWERVR_ROGUE_1_13=m
      # CONFIG_DRM_POWERVR_ROGUE_1_17=y
    }];
  };
}
