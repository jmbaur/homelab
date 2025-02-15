{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.hardware.chromebook.qualcomm = lib.mkEnableOption "qualcomm chromebook";

  config = lib.mkIf config.hardware.chromebook.qualcomm {
    boot.kernelPackages = pkgs.linuxPackages_latest;

    boot.kernelParams = [
      "pd_ignore_unused"
      "clk_ignore_unused"
      "console=ttyMSM0,115200"
    ];

    boot.kernelPatches = [
      {
        name = "qcom-enablement";
        patch = null;
        extraStructuredConfig = {
          # ARM_SMMU_QCOM = lib.kernel.yes;
          # INTERCONNECT_QCOM = lib.kernel.yes;
          # INTERCONNECT_QCOM_OSM_L3 = lib.kernel.yes;
          # INTERCONNECT_QCOM_SC7180 = lib.kernel.yes;
          # PHY_QCOM_QUSB2 = lib.kernel.yes;
          # PHY_QCOM_USB_SNPS_FEMTO_V2 = lib.kernel.yes;
          # QCOM_GENI_SE = lib.kernel.yes;
          # QCOM_IPCC = lib.kernel.yes;
          # QCOM_LLCC = lib.kernel.yes;
          # QCOM_PDC = lib.kernel.yes;
          # QCOM_PIL_INFO = lib.kernel.yes;
          # QCOM_Q6V5_COMMON = lib.kernel.yes;
          # QCOM_RPMH = lib.kernel.yes;
          # QCOM_RPMHPD = lib.kernel.yes;
          # QCOM_RPROC_COMMON = lib.kernel.yes;
          # QCOM_SCM = lib.kernel.yes;
          # QCOM_SMEM = lib.kernel.yes;
          # QCOM_SMP2P = lib.kernel.yes;
          # QCOM_SOCINFO = lib.kernel.yes;
          # QCOM_SPMI_ADC5 = lib.kernel.yes;
          # QCOM_SPMI_ADC_TM5 = lib.kernel.yes;
          # QCOM_SPMI_TEMP_ALARM = lib.kernel.yes;
          # QCOM_STATS = lib.kernel.yes;
          # QCOM_SYSMON = lib.kernel.yes;
          # QCOM_TSENS = lib.kernel.yes;
          # QCOM_WDT = lib.kernel.yes;
          # SC_CAMCC_7180 = lib.kernel.yes;
          # SC_CAMCC_7280 = lib.kernel.yes;
          # SC_DISPCC_7180 = lib.kernel.yes;
          # SC_DISPCC_7280 = lib.kernel.yes;
          # SC_GPUCC_7180 = lib.kernel.yes;
          # SC_GPUCC_7280 = lib.kernel.yes;
          # SC_LPASSCC_7280 = lib.kernel.yes;
          # SC_LPASS_CORECC_7180 = lib.kernel.yes;
          # SC_LPASS_CORECC_7280 = lib.kernel.yes;
          # SC_VIDEOCC_7180 = lib.kernel.yes;
          # SC_VIDEOCC_7280 = lib.kernel.yes;
        };
      }
    ];

    boot.initrd.availableKernelModules = [
      "dispcc-sc7180"
      "extcon-qcom-spmi-misc"
      "gcc-sc7180"
      "gpucc-sc7180"
      "i2c-qcom-geni"
      "icc-bwmon"
      "icc-osm-l3"
      "icc-smd-rpm"
      "lpasscorecc-sc7180"
      "mss-sc7180"
      "onboard_usb_hub"
      "pcie-qcom-ep"
      "phy-qcom-apq8064-sata"
      "phy-qcom-edp"
      "phy-qcom-eusb2-repeater"
      "phy-qcom-ipq4019-usb"
      "phy-qcom-ipq806x-sata"
      "phy-qcom-ipq806x-usb"
      "phy-qcom-pcie2"
      "phy-qcom-qmp-combo"
      "phy-qcom-qmp-pcie"
      "phy-qcom-qmp-pcie-msm8996"
      "phy-qcom-qmp-ufs"
      "phy-qcom-qmp-usb"
      "phy-qcom-qusb2"
      "phy-qcom-sgmii-eth"
      "phy-qcom-snps-eusb2"
      "phy-qcom-snps-femto-v2"
      "phy-qcom-usb-hs"
      "phy-qcom-usb-hs-28nm"
      "phy-qcom-usb-hsic"
      "phy-qcom-usb-ss"
      "qcom-labibb-regulator"
      "qcom-pm8008"
      "qcom_common"
      "qcom_pil_info"
      "qcom_pmic_tcpm"
      "qcom_q6v5"
      "qcom_q6v5_adsp"
      "qcom_q6v5_mss"
      "qcom_q6v5_pas"
      "qcom_q6v5_pas"
      "qcom_q6v5_wcss"
      "qcom_rpm"
      "qcom_rpm-regulator"
      "qcom_sysmon"
      "qcom_usb_vbus-regulator"
      "qcom_wcnss_pil"
      "reset-qcom-pdc"
      "spi-geni-qcom"
      "spi-qcom-qspi"
      "uas"
      "usb_storage"
    ];
  };
}
