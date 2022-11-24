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

            extraStructuredConfig = with lib.kernel; {
              wireless = {
                ATH10K = module;
                ATH10K_DEBUG = yes;
                ATH10K_DEBUGFS = yes;
                ATH10K_SDIO = module;
                ATH10K_TRACING = yes;
              };
              sound = {
                SND_SOC_MT8173 = yes;
                SND_SOC_MT8173_RT5650 = yes;
                SND_SOC_MT8173_RT5650_RT5514 = yes;
                SND_SOC_MT8173_RT5650_RT5676 = yes;
                SND_SOC_MT8183 = yes;
                SND_SOC_MT8183_DA7219_MAX98357A = yes;
                SND_SOC_MT8183_MT6358_TS3A227E_MAX98357A = yes;
                SND_SOC_MT8186 = yes;
                SND_SOC_MT8186_MT6366_DA7219_MAX98357 = yes;
                SND_SOC_MT8186_MT6366_RT1019_RT5682S = yes;
                SND_SOC_MT8192 = yes;
                SND_SOC_MT8192_MT6359_RT1015_RT5682 = yes;
                SND_SOC_SOF_MT8186 = module;
                SND_SOC_SOF_MTK_TOPLEVEL = yes;
                SND_SOC_SOF_OF = yes;
                SND_SOC_SOF_TOPLEVEL = yes;
              };
              video = {
                DRM = yes;
                DRM_ANALOGIX_ANX7625 = yes;
                DRM_ANALOGIX_ANX78XX = yes;
                DRM_DP_AUX_CHARDEV = yes;
                DRM_EVDI = module;
                DRM_ITE_IT6505 = yes;
                DRM_MEDIATEK = yes;
                DRM_MEDIATEK_HDMI = yes;
                DRM_PANEL_BOE_TV101WUM_NL6 = yes;
                DRM_PANEL_EDP = yes;
                DRM_PANEL_INNOLUX_HIMAX8279D = yes;
                DRM_PANEL_INNOLUX_P079ZCA = yes;
                DRM_PANEL_SIMPLE = yes;
                DRM_PANFROST = yes;
                DRM_PARADE_PS8640 = yes;
                DRM_POWERVR_ROGUE_1_13 = module;
                DRM_POWERVR_ROGUE_1_17 = yes;
                DRM_UDL = yes;
                DRM_VGEM = yes;
                MALI_BIFROST = yes;
                MALI_BIFROST_EXPERT = yes;
                MALI_BIFROST_PLATFORM_NAME = freeform "mediatek";
              };
              power-management = {
                CPU_BOOST = yes;
                CPU_FREQ = yes;
                CPU_FREQ_DEFAULT_GOV_PERFORMANCE = yes;
                CPU_FREQ_GOV_CONSERVATIVE = yes;
                CPU_FREQ_GOV_ONDEMAND = yes;
                CPU_FREQ_GOV_POWERSAVE = yes;
                CPU_FREQ_GOV_SCHEDUTIL = yes;
                CPU_IDLE = yes;
                CPU_THERMAL = yes;
              };
              misc = {
                ARCH_MEDIATEK = yes;
                ARM_MEDIATEK_CCI_DEVFREQ = yes;
                ARM_MEDIATEK_CPUFREQ = yes;
                ARM_SMC_WATCHDOG = yes;
                CROS_EC = yes;
                CROS_EC_PD_UPDATE = yes;
                CROS_EC_SENSORHUB = module;
                CROS_EC_SPI = yes;
                GOOGLE_COREBOOT_TABLE = yes;
                GOOGLE_FIRMWARE = yes;
                GOOGLE_MEMCONSOLE_COREBOOT = yes;
                GOOGLE_VPD = yes;
              };
            };

            extraMeta.branch = "chromeos-5.15";
          } // (args.argsOverride or { }));
      in
      pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor (pkgs.callPackage linux_chromeos_5-15 { }));
  };
}
