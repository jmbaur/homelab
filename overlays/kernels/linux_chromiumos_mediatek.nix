{ linuxKernel, lib, ... }:
linuxKernel.kernels.linux_6_0.override {
  structuredExtraConfig = with lib.kernel; (lib.mapAttrs (_: lib.mkForce) {
    ANDROID = yes;
    ANDROID_BINDER_IPC = yes;
    ARCH_MEDIATEK = yes;
    ARCH_MMAP_RND_BITS = freeform "24";
    ARCH_MMAP_RND_COMPAT_BITS = freeform "16";
    ARM64_SW_TTBR0_PAN = yes;
    ARMV8_DEPRECATED = yes;
    ARM_CPUIDLE = yes;
    ARM_MEDIATEK_CCI_DEVFREQ = yes;
    ARM_MEDIATEK_CPUFREQ = yes;
    ARM_PSCI_CPUIDLE = yes;
    ARM_SMC_WATCHDOG = yes;
    ATH10K = module;
    ATH10K_DEBUG = yes;
    ATH10K_DEBUGFS = yes;
    ATH10K_SDIO = module;
    ATH10K_TRACING = yes;
    BACKLIGHT_CLASS_DEVICE = yes;
    BACKLIGHT_PWM = yes;
    BATTERY_SBS = yes;
    BT = module;
    BT_AOSPEXT = yes;
    BT_FEATURE_DEBUG = yes;
    BT_FEATURE_DEBUG_FUNC_NAMES = yes;
    BT_HCIBFUSB = module;
    BT_HCIBTSDIO = module;
    BT_HCIBTUSB = module;
    BT_HCIBTUSB_AUTOSUSPEND = yes;
    BT_HCIBTUSB_INTERVAL = yes;
    BT_HCIBTUSB_MTK = yes;
    BT_HCIUART = module;
    BT_HCIUART_QCA = yes;
    BT_HCIUART_RTL = yes;
    BT_HCIVHCI = module;
    BT_HIDP = module;
    BT_MRVL = module;
    BT_MRVL_SDIO = module;
    BT_MSFTEXT = yes;
    BT_MTKSDIO = module;
    BT_RFCOMM = module;
    CFG80211 = module;
    CFG80211_CERTIFICATION_ONUS = yes;
    CFG80211_DEBUGFS = yes;
    CFG80211_WEXT = yes;
    CHARGER_CROS_USBPD = yes;
    CHARGER_GPIO = yes;
    CHROME_PLATFORMS = yes;
    CLS_U32_MARK = yes;
    COMPAT = yes;
    CONFIGFS_FS = yes;
    CONNECTOR = yes;
    CP15_BARRIER_EMULATION = yes;
    CPUSETS = yes;
    CPU_BOOST = yes;
    CPU_FREQ = yes;
    CPU_FREQ_DEFAULT_GOV_PERFORMANCE = yes;
    CPU_FREQ_GOV_CONSERVATIVE = yes;
    CPU_FREQ_GOV_ONDEMAND = yes;
    CPU_FREQ_GOV_POWERSAVE = yes;
    CPU_FREQ_GOV_SCHEDUTIL = yes;
    CPU_FREQ_GOV_USERSPACE = yes;
    CPU_FREQ_STAT = yes;
    CPU_IDLE = yes;
    CPU_IDLE_GOV_LADDER = yes;
    CPU_IDLE_GOV_MENU = yes;
    CPU_IDLE_GOV_TEO = yes;
    CPU_THERMAL = yes;
    CRC7 = module;
    CROS_EC = yes;
    CROS_EC_PD_UPDATE = yes;
    CROS_EC_RPMSG = module;
    CROS_EC_SENSORHUB = module;
    CROS_EC_SPI = yes;
    DEVFREQ_GOV_PERFORMANCE = yes;
    DEVFREQ_GOV_POWERSAVE = yes;
    DEVFREQ_GOV_USERSPACE = yes;
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
    DRM_POWERVR_ROGUE_1_17 = yes;
    DRM_UDL = yes;
    DRM_VGEM = yes;
    ECRYPT_FS = yes;
    EEPROM_AT24 = yes;
    EMBEDDED = yes;
    ENCRYPTED_KEYS = yes;
    ENERGY_MODEL = yes;
    FUNCTION_PROFILER = yes;
    FUNCTION_TRACER = yes;
    FUSE_FS = module;
    GENERIC_ADC_THERMAL = yes;
    GOOGLE_COREBOOT_TABLE = yes;
    GOOGLE_FIRMWARE = yes;
    GOOGLE_MEMCONSOLE_COREBOOT = yes;
    GOOGLE_VPD = yes;
    GPIO_SYSFS = yes;
    HARDENED_USERCOPY = yes;
    HARDLOCKUP_DETECTOR_BUDDY_CPU = yes;
    HFSPLUS_FS = module;
    HIDRAW = yes;
    HID_APPLE = module;
    HID_BATTERY_STRENGTH = yes;
    HID_CHERRY = module;
    HID_CHICONY = module;
    HID_GOOGLE_HAMMER = module;
    HID_HOLTEK = module;
    HID_KENSINGTON = module;
    HID_LOGITECH = module;
    HID_LOGITECH_DJ = module;
    HID_MAGICMOUSE = module;
    HID_MICROSOFT = module;
    HID_MULTITOUCH = yes;
    HID_NINTENDO = yes;
    HID_PLANTRONICS = module;
    HID_PRIMAX = module;
    HID_QUICKSTEP = module;
    HID_RMI = module;
    HID_SONY = module;
    HID_THINGM = module;
    HID_VIVALDI = module;
    HID_WACOM = module;
    HID_WIIMOTE = module;
    HIGH_RES_TIMERS = yes;
    HIST_TRIGGERS = yes;
    HW_RANDOM = yes;
    HZ_1000 = yes;
    I2C_CHARDEV = yes;
    I2C_CROS_EC_TUNNEL = yes;
    I2C_HID_OF = yes;
    I2C_HID_OF_GOODIX = yes;
    I2C_MT65XX = yes;
    I2C_STUB = module;
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
    INPUT_EVDEV = yes;
    INPUT_FF_MEMLESS = yes;
    INPUT_JOYDEV = module;
    INPUT_JOYSTICK = yes;
    INPUT_MISC = yes;
    INPUT_TABLET = yes;
    INPUT_TOUCHSCREEN = yes;
    INPUT_UINPUT = module;
    IOSCHED_BFQ = yes;
    IRQ_TIME_ACCOUNTING = yes;
    ISO9660_FS = module;
    JOLIET = yes;
    JOYSTICK_IFORCE = module;
    JOYSTICK_IFORCE_USB = module;
    JOYSTICK_XPAD = module;
    JOYSTICK_XPAD_FF = yes;
    JOYSTICK_XPAD_LEDS = yes;
    JUMP_LABEL = yes;
    KEYBOARD_CROS_EC = yes;
    KEYBOARD_GPIO = yes;
    MAC80211 = module;
    MAC80211_DEBUGFS = yes;
    MAC80211_DEBUG_MENU = yes;
    MAC80211_HWSIM = module;
    MAC80211_LEDS = yes;
    MAC80211_VERBOSE_DEBUG = yes;
    MAC_PARTITION = yes;
    MALI_BIFROST = yes;
    MALI_BIFROST_EXPERT = yes;
    MALI_BIFROST_PLATFORM_NAME = freeform "mediatek";
    MEDIATEK_MT6577_AUXADC = yes;
    MEDIATEK_WATCHDOG = yes;
    MEDIA_CAMERA_SUPPORT = yes;
    MEDIA_PLATFORM_SUPPORT = yes;
    MEDIA_SUPPORT = yes;
    MEDIA_SUPPORT_FILTER = yes;
    MEDIA_USB_SUPPORT = yes;
    MFD_MT6397 = yes;
    MMC = yes;
    MMC_BLOCK_MINORS = freeform "16";
    MMC_MTK = yes;
    MMC_SDHCI = yes;
    MMC_SDHCI_PLTFM = yes;
    MMC_TEST = module;
    MOUSE_CYAPA = yes;
    MOUSE_ELAN_I2C = yes;
    MT7921E = module;
    MT7921S = module;
    MTD = yes;
    MTD_CMDLINE_PARTS = yes;
    MTD_PARTITIONED_MASTER = yes;
    MTD_SPI_NOR = yes;
    MTK_ADSP_IPC = yes;
    MTK_ADSP_MBOX = yes;
    MTK_CMDQ = yes;
    MTK_EFUSE = yes;
    MTK_IOMMU = yes;
    MTK_PMIC_WRAP = yes;
    MTK_SOC_THERMAL_LVTS = yes;
    MTK_SVS = yes;
    MTK_THERMAL = yes;
    MWIFIEX = module;
    MWIFIEX_SDIO = module;
    PCI = yes;
    PCIEAER = yes;
    PCIEASPM_POWER_SUPERSAVE = yes;
    PCIEPORTBUS = yes;
    PCIE_MEDIATEK = yes;
    PHYLIB = yes;
    PHY_MTK_TPHY = yes;
    PKGLIST = yes;
    PL330_DMA = yes;
    PSI = yes;
    PSTORE = yes;
    PSTORE_CONSOLE = yes;
    PSTORE_PMSG = yes;
    PSTORE_RAM = yes;
    PWM = yes;
    PWM_CROS_EC = yes;
    PWM_MTK_DISP = yes;
    RANDOMIZE_BASE = yes;
    RCU_EXPERT = yes;
    RCU_NOCB_CPU = yes;
    RCU_NOCB_CPU_DEFAULT_ALL = yes;
    REGULATOR_CROS_EC = yes;
    REGULATOR_DA9211 = yes;
    REGULATOR_FIXED_VOLTAGE = yes;
    REGULATOR_GPIO = yes;
    REGULATOR_MT6315 = yes;
    REGULATOR_MT6358 = yes;
    REGULATOR_MT6397 = yes;
    REGULATOR_PWM = yes;
    REGULATOR_USERSPACE_CONSUMER = yes;
    REGULATOR_VIRTUAL_CONSUMER = yes;
    RT2800USB = module;
    RT2800USB_RT3573 = yes;
    RT2800USB_RT53XX = yes;
    RT2800USB_RT55XX = yes;
    RT2800USB_UNKNOWN = yes;
    RT2X00 = module;
    RTC_CLASS = yes;
    RTC_DRV_CROS_EC = yes;
    RTC_DRV_MT6397 = yes;
    RTW88 = module;
    RTW88_8822BE = module;
    RTW88_8822CE = module;
    RTW88_DEBUG = yes;
    RTW88_DEBUGFS = yes;
    RT_GROUP_SCHED = yes;
    SCHEDSTATS = yes;
    SCHED_MC = yes;
    SCHED_TRACER = yes;
    SCSI = yes;
    SCSI_SCAN_ASYNC = yes;
    SCSI_SPI_ATTRS = yes;
    SECURITY = yes;
    SECURITY_CHROMIUMOS = yes;
    SECURITY_DMESG_RESTRICT = yes;
    SECURITY_LANDLOCK = yes;
    SECURITY_LOADPIN = yes;
    SECURITY_LOADPIN_ENFORCE = yes;
    SECURITY_NETWORK = yes;
    SECURITY_SAFESETID = yes;
    SECURITY_SELINUX = yes;
    SECURITY_SELINUX_BOOTPARAM = yes;
    SECURITY_SELINUX_PERMISSIVE_DONTAUDIT = yes;
    SECURITY_YAMA = yes;
    SENSORS_TMP401 = yes;
    SERIAL_8250 = yes;
    SERIAL_8250_CONSOLE = yes;
    SERIAL_8250_MT6577 = yes;
    SERIAL_DEV_BUS = yes;
    SERIAL_OF_PLATFORM = yes;
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
    SOFT_WATCHDOG = module;
    SOUND = yes;
    SPI = yes;
    SPI_GPIO = yes;
    SPI_MT65XX = yes;
    SPI_MTK_NOR = yes;
    SPI_SPIDEV = yes;
    SPMI = yes;
    SPMI_MTK_PMIF = yes;
    SX9324 = module;
    TCG_TIS_I2C_CR50 = yes;
    TCG_TIS_I2C_INFINEON = yes;
    TCG_TIS_SPI = yes;
    TCG_TIS_SPI_CR50 = yes;
    TCG_TPM = yes;
    TEST_ASYNC_DRIVER_PROBE = module;
    TEST_FIRMWARE = module;
    TEST_LKM = module;
    TEST_UDELAY = module;
    THERMAL = yes;
    THERMAL_DEFAULT_GOV_POWER_ALLOCATOR = yes;
    THERMAL_GOV_POWER_ALLOCATOR = yes;
    THERMAL_GOV_STEP_WISE = yes;
    THERMAL_GOV_USER_SPACE = yes;
    THERMAL_WRITABLE_TRIPS = yes;
    TOUCHSCREEN_ATMEL_MXT = yes;
    TOUCHSCREEN_ELAN = yes;
    TOUCHSCREEN_MELFAS_MIP4 = yes;
    TOUCHSCREEN_USB_COMPOSITE = module;
    TYPEC = yes;
    UHID = yes;
    USB = yes;
    USBIP_CORE = module;
    USBIP_VHCI_HCD = module;
    USB_ACM = yes;
    USB_ANNOUNCE_NEW_DEVICES = yes;
    USB_CONFIGFS = module;
    USB_CONFIGFS_F_FS = yes;
    USB_DUMMY_HCD = module;
    USB_DWC3 = yes;
    USB_EHCI_HCD = yes;
    USB_EHCI_HCD_PLATFORM = yes;
    USB_EHCI_ROOT_HUB_TT = yes;
    USB_GADGET = yes;
    USB_HIDDEV = yes;
    USB_IPHETH = module;
    USB_MASS_STORAGE = module;
    USB_MON = yes;
    USB_MTU3 = yes;
    USB_MTU3_HOST = yes;
    USB_NET_AQC111 = module;
    USB_NET_DM9601 = module;
    USB_NET_MCS7830 = module;
    USB_NET_RNDIS_WLAN = module;
    USB_NET_SMSC75XX = module;
    USB_NET_SMSC95XX = module;
    USB_OHCI_HCD = yes;
    USB_OHCI_HCD_PLATFORM = yes;
    USB_PEGASUS = module;
    USB_RTL8150 = module;
    USB_RTL8152 = module;
    USB_SERIAL = module;
    USB_SERIAL_CH341 = module;
    USB_SERIAL_CP210X = module;
    USB_SERIAL_FTDI_SIO = module;
    USB_SERIAL_GENERIC = yes;
    USB_SERIAL_KEYSPAN = module;
    USB_SERIAL_OPTION = module;
    USB_SERIAL_OTI6858 = module;
    USB_SERIAL_PL2303 = module;
    USB_SERIAL_QUALCOMM = module;
    USB_SERIAL_SIERRAWIRELESS = module;
    USB_SERIAL_SIMPLE = module;
    USB_STORAGE = yes;
    USB_UAS = yes;
    USB_VIDEO_CLASS = module;
    USB_XHCI_HCD = yes;
    V4L_MEM2MEM_DRIVERS = yes;
    V4L_PLATFORM_DRIVERS = yes;
    VFAT_FS = module;
    VIDEO_DW9768 = module;
    VIDEO_MEDIATEK_JPEG = module;
    VIDEO_MEDIATEK_MDP = module;
    VIDEO_MEDIATEK_MDP3 = module;
    VIDEO_MEDIATEK_VCODEC = module;
    VIDEO_MEDIATEK_VPU = yes;
    VIDEO_OV02A10 = module;
    VIDEO_OV5695 = module;
    VIDEO_OV8856 = module;
    WATCHDOG = yes;
  });
}
