{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.hardware.chromebook.trogdor.enable = lib.mkEnableOption "trogdor";

  config = lib.mkIf config.hardware.chromebook.trogdor.enable {
    hardware.chromebook.enable = true;

    hardware.qualcomm.enable = true;

    hardware.firmware = [
      (pkgs.fetchFromGitLab {
        owner = "jenneron";
        repo = "firmware-google-trogdor";
        rev = "bae7f2275cd7ccd73111662e25b124c082f296ea";
        postFetch = ''
          mkdir -p $out/lib/firmware
          mv $out/qcom $out/lib/firmware
        '';
        hash = "sha256-WAGAweY1u2r9n/wDaFavjq6ju0E7P6HC07+wO9BnigU=";
      })
      (pkgs.extractLinuxFirmwareDirectory "qca")
      (pkgs.extractLinuxFirmwareDirectory "qcom")
      (pkgs.extractLinuxFirmwareDirectory "ath10k")
    ];

    boot.kernelParams = [ "deferred_probe_timeout=30" ];

    boot.kernelPatches = [
      {
        name = "trogdor-hardware-enablement";
        patch = null;
        structuredExtraConfig = {
          RMI4_F11 = lib.kernel.yes;
          RMI4_F12 = lib.kernel.yes;
          RMI4_F30 = lib.kernel.yes;
          RMI4_F34 = lib.kernel.yes;
          RMI4_F3A = lib.kernel.yes;
          RMI4_F55 = lib.kernel.yes;
          RMNET = lib.kernel.yes;
          QRTR = lib.kernel.yes;
        };
      }
    ];

    boot.initrd.availableKernelModules = [
      "rtc_cros_ec"

      "i2c-hid-of"
      "i2c-hid-of-goodix"
      "elan-i2c"
      "elants-i2c"
      "cros-ec-keyb"
      "sbs-battery"

      # TODO(jared): filter this down
      "icc_bwmon"
      "lpasscc_sc8280xp"
      "phy_qcom_apq8064_sata"
      "phy_qcom_eusb2_repeater"
      "phy_qcom_ipq4019_usb"
      "phy_qcom_ipq806x_sata"
      "phy_qcom_ipq806x_usb"
      "phy_qcom_m31"
      "phy_qcom_pcie2"
      "phy_qcom_qmp_pcie_msm8996"
      "phy_qcom_qmp_ufs"
      "phy_qcom_qmp_usb"
      "phy_qcom_qmp_usb_legacy"
      "phy_qcom_qmp_usbc"
      "phy_qcom_qusb2"
      "phy_qcom_sgmii_eth"
      "phy_qcom_snps_eusb2"
      "phy_qcom_snps_femto_v2"
      "phy_qcom_usb_hs"
      "phy_qcom_usb_hs_28nm"
      "phy_qcom_usb_hsic"
      "phy_qcom_usb_ss"
      "pmic_glink"
      "qcom_glink_smem"
      "qcom_q6v5_pas" # This module loads a lot of FW blobs
      "qcom_rpm"
      "uas"
      "ucsi_glink"

      # storage
      "nvme"
      "phy_qcom_qmp_pcie"

      # keyboard
      "i2c_hid_of"
      "i2c_qcom_geni"

      # display
      "dispcc_sc8280xp"
      "gpio_sbu_mux"
      "gpucc_sc8280xp"
      "leds_qcom_lpg"
      "msm"
      "panel_edp"
      "phy_qcom_edp"
      "phy_qcom_qmp_combo"
      "pmic_glink_altmode"
      "pwm_bl"
      "qrtr"

      "phy-qcom-eusb2-repeater"
      "phy-qcom-qmp-pcie"
      "phy-qcom-qmp-pcie-msm8996"
      "phy-qcom-qmp-ufs"
      "phy-qcom-qmp-usb"
      "phy-qcom-qmp-usb-legacy"
      "phy-qcom-qmp-usbc"
      "phy-qcom-qusb2"
      "phy-qcom-snps-eusb2"
      "phy-qcom-usb-hs"
      "phy-qcom-usb-hs-28nm"
      "phy-qcom-usb-hsic"
      "phy-qcom-usb-ss"
      "qcom_pmic_tcpm"
      "qcom_usb_vbus-regulator"
      "spi-geni-qcom"
      "videocc-sc7180"
      "dispcc-sc7180"
      "onboard_usb_dev" # crucial
    ];

    boot.initrd.systemd.services.adjust-storage-iommu = {
      wantedBy = [ "initrd.target" ];
      before = [ "initrd-fs.target" ];
      script = ''
        # This script relaxes iommu for the devices, relaxing memory
        # protection, but we consider it a fine tradeoff because those
        # hardware blocks don't have firmware on them.

        # It Increases eMMC speed by 15% according to gnome disks benchmark
        # with sample size 1000 MiB and number of samples 2.

        iommus="
          /sys/devices/platform/soc@0/7c4000.mmc/iommu_group/type
          /sys/devices/platform/soc@0/8804000.mmc/iommu_group/type
          /sys/devices/platform/soc@0/a6f8800.usb/a600000.usb/iommu_group/type
        "

        for iommu in $iommus; do
          [ -f "$iommu" ] && echo "DMA-FQ" > "$iommu"
        done
      '';
    };

  };
}
