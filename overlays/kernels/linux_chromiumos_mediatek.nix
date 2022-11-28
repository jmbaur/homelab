{ linuxKernel, lib, ... }:
linuxKernel.kernels.linux_6_0.override {
  structuredExtraConfig = with lib.kernel; {
    ATH10K = module;
    ATH10K_DEBUG = yes;
    ATH10K_DEBUGFS = yes;
    ATH10K_SDIO = module;
    ATH10K_TRACING = yes;
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
  };
}
