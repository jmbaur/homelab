{ lib, pkgs, ... }:
{
  config = lib.mkMerge [
    # TODO(jared): belongs in hardware module
    {
      hardware.qualcomm.enable = true;

      nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

      hardware.deviceTree.name = "qcom/x1e78100-lenovo-thinkpad-t14s.dtb";

      hardware.firmware = [
        pkgs.linux-firmware
        pkgs.t14s-firmware
      ];

      boot.kernelPackages = pkgs.linuxPackagesFor (
        pkgs.callPackage
          (
            { buildLinux, ... }@args:
            buildLinux (
              args
              // {
                version = "6.13.0";
                modDirVersion = "6.13.0";

                # TODO(jared): remove this
                ignoreConfigErrors = true;

                src = pkgs.fetchFromGitHub {
                  owner = "jhovold";
                  repo = "linux";
                  # wip/x1e80100-6.13
                  rev = "0df45c8ef99147234f541062be775907b28ad768";
                  hash = "sha256-IwZ/pOwiHV2d2OiTzI/eSLuEwNJhV/1Ud7QvBkMRyDs=";
                };
                kernelPatches = (args.kernelPatches or [ ]);

                extraMeta.branch = "6.13";
              }
              // (args.argsOverride or { })
            )
          )
          {
            defconfig = "johan_defconfig";
          }
      );

      boot.consoleLogLevel = 7;

      boot.kernelParams = [
        "clk_ignore_unused"
        "pd_ignore_unused"
      ];

      boot.initrd.includeDefaultModules = false;

      boot.initrd.availableKernelModules = [
        # storage
        "nvme"
        "pcie_qcom"
        "phy_qcom_qmp_pcie"
        "tcsrcc_x1e80100"
        "usb_storage"
        "phy_qcom_snps_eusb2"
        "phy_qcom_qmp_combo"

        # keyboard
        "i2c_hid_of"
        "i2c_qcom_geni"

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
        "usb_storage"

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
      ];

      # TODO(jared): ACPI not enabled in johan_defconfig, needed by tpm-crb
      # kernel module.
      boot.initrd.systemd.tpm2.enable = false;
      custom.recovery.modules = [
        {
          boot.initrd.includeDefaultModules = false;
          boot.initrd.systemd.tpm2.enable = false;
        }
      ];
    }
    {
      # custom.dev.enable = true;
      # custom.desktop.enable = false;
      # custom.common.nativeBuild = true;
      custom.recovery.targetDisk = "/dev/nvme0n1";
      boot.loader.efi.canTouchEfiVariables = false;
    }
  ];
}
