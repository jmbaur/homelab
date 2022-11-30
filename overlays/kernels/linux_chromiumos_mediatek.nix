{ linuxKernel, lib, ... }:
linuxKernel.kernels.linux_6_0.override {
  structuredExtraConfig = with lib.kernel; {

    # Wireless
    ATH10K = module;
    ATH10K_DEBUG = yes;
    ATH10K_DEBUGFS = yes;
    ATH10K_SDIO = module;
    ATH10K_TRACING = yes;

    # Sound
    SND = yes;
    SND_ALOOP = module;
    SND_DUMMY = module;
    SND_HRTIMER = module;
    SND_SEQUENCER = module;
    SND_SEQ_DUMMY = module;
    SND_SIMPLE_CARD = yes;
    SND_SOC = yes;
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
    SND_USB_AUDIO = module;

    # TPM
    TCG_TIS_I2C_CR50 = yes;
    TCG_TIS_I2C_INFINEON = yes;
    TCG_TIS_SPI = yes;
    TCG_TIS_SPI_CR50 = yes;
    TCG_TPM = yes;

    # Embedded controller
    CROS_EC = lib.mkForce yes;
    CROS_EC_PD_UPDATE = yes;
    CROS_EC_RPMSG = module;
    CROS_EC_SENSORHUB = module;
    CROS_EC_SPI = lib.mkForce yes;
    EXTCON_USBC_CROS_EC = yes;
    I2C_CROS_EC_TUNNEL = yes;
    IIO = yes;
    IIO_CROS_EC_ACTIVITY = module;
    IIO_CROS_EC_BARO = module;
    IIO_CROS_EC_LIGHT_PROX = module;
    IIO_CROS_EC_SENSORS = module;
    IIO_CROS_EC_SENSORS_CORE = module;
    IIO_CROS_EC_SENSORS_LID_ANGLE = module;
    IIO_CROS_EC_SENSORS_SYNC = module;
    IIO_HRTIMER_TRIGGER = module;
    IIO_SW_TRIGGER = module;
    IIO_SYSFS_TRIGGER = module;
    KEYBOARD_CROS_EC = yes;
    PWM = yes;
    PWM_CROS_EC = yes;
    RTC_DRV_CROS_EC = yes;

    # Mediatek settings
    MTK_ADSP_IPC = yes;
    MTK_ADSP_MBOX = yes;
    MTK_CMDQ = yes;
    MTK_EFUSE = yes;
    MTK_IOMMU = yes;
    MTK_PMIC_WRAP = yes;
    # MTK_SOC_THERMAL_LVTS = yes; # TODO(jared): does not exist in mainline
    MTK_SVS = yes;
    MTK_THERMAL = yes;

    # Google firmware
    GOOGLE_COREBOOT_TABLE = yes;
    GOOGLE_FIRMWARE = yes;
    GOOGLE_MEMCONSOLE_COREBOOT = yes;
    GOOGLE_VPD = yes;

    # # Video
    # DRM = yes;
    # DRM_ANALOGIX_ANX7625 = yes;
    # DRM_ANALOGIX_ANX78XX = yes;
    # DRM_DP_AUX_CHARDEV = yes;
    # # DRM_EVDI=module; # TODO(jared): does not exist in mainline
    # DRM_ITE_IT6505 = yes;
    # DRM_MEDIATEK = yes;
    # DRM_MEDIATEK_HDMI = yes;
    # DRM_PANEL_BOE_TV101WUM_NL6 = yes;
    # DRM_PANEL_EDP = yes;
    # DRM_PANEL_INNOLUX_HIMAX8279D = yes;
    # DRM_PANEL_INNOLUX_P079ZCA = yes;
    # DRM_PANEL_SIMPLE = yes;
    # DRM_PANFROST = yes;
    # DRM_PARADE_PS8640 = yes;
    # # DRM_POWERVR_ROGUE_1_17=yes; # TODO(jared): does not exist in mainline
    # DRM_UDL = yes;
    # DRM_VGEM = yes;
    # # MALI_BIFROST=yes; # TODO(jared): does not exist in mainline
    # # MALI_BIFROST_EXPERT=yes; # TODO(jared): does not exist in mainline
    # # MALI_BIFROST_PLATFORM_NAME=freeform "mediatek" # TODO(jared): does not exist in mainline
    # VIDEO_DW9768 = module;
    # VIDEO_MEDIATEK_JPEG = module;
    # VIDEO_MEDIATEK_MDP3 = module;
    # VIDEO_MEDIATEK_MDP = module;
    # VIDEO_MEDIATEK_VCODEC = module;
    # VIDEO_MEDIATEK_VPU = yes;
    # VIDEO_OV02A10 = module;
    # VIDEO_OV5695 = module;
    # VIDEO_OV8856 = module;

  };
}
