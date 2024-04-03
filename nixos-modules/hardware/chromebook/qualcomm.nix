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
        extraStructuredConfig = with lib.kernel; {
          ARM_SMMU_QCOM = yes;
          INTERCONNECT_QCOM = yes;
          INTERCONNECT_QCOM_OSM_L3 = yes;
          INTERCONNECT_QCOM_SC7180 = yes;
          PHY_QCOM_QUSB2 = yes;
          PHY_QCOM_USB_SNPS_FEMTO_V2 = yes;
          QCOM_GENI_SE = yes;
          QCOM_IPCC = yes;
          QCOM_LLCC = yes;
          QCOM_PDC = yes;
          QCOM_PIL_INFO = yes;
          QCOM_Q6V5_COMMON = yes;
          QCOM_RPMH = yes;
          QCOM_RPMHPD = yes;
          QCOM_RPROC_COMMON = yes;
          QCOM_SCM = yes;
          QCOM_SMEM = yes;
          QCOM_SMP2P = yes;
          QCOM_SOCINFO = yes;
          QCOM_SPMI_ADC5 = yes;
          QCOM_SPMI_ADC_TM5 = yes;
          QCOM_SPMI_TEMP_ALARM = yes;
          QCOM_STATS = yes;
          QCOM_SYSMON = yes;
          QCOM_TSENS = yes;
          QCOM_WDT = yes;
          SC_CAMCC_7180 = yes;
          SC_CAMCC_7280 = yes;
          SC_DISPCC_7180 = yes;
          SC_DISPCC_7280 = yes;
          SC_GPUCC_7180 = yes;
          SC_GPUCC_7280 = yes;
          SC_LPASSCC_7280 = yes;
          SC_LPASS_CORECC_7180 = yes;
          SC_LPASS_CORECC_7280 = yes;
          SC_MSS_7180 = yes;
          SC_VIDEOCC_7180 = yes;
          SC_VIDEOCC_7280 = yes;
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
