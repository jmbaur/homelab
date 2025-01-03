# TODO(jared): wifi: https://bugzilla.kernel.org/show_bug.cgi?id=219454

{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkDefault
    mkEnableOption
    mkIf
    replaceStrings
    ;

  patchName =
    name: (replaceStrings [ " " "[" "]" "," "/" ":" ] [ "-" "" "" "_" "_" "" ] name) + ".patch";

  wdk2023_syshacks = pkgs.fetchFromGitHub {
    owner = "jglathe";
    repo = "wdk2023_syshacks";
    rev = "359b6c2304516f5ea3f754214625a720cc976ef6";
    hash = "sha256-84QB1jGQwQWEq3gZ3I1vG3DKAxXCC5eKbkZo2egmFuU=";
  };
in
{
  options.hardware.blackrock.enable = mkEnableOption "microsoft,blackrock";

  config = mkIf config.hardware.blackrock.enable {
    nixpkgs.hostPlatform = mkDefault "aarch64-linux";

    hardware.qualcomm.enable = true;

    boot.kernelPackages = pkgs.linuxPackages_testing;

    boot.consoleLogLevel = 7;

    boot.kernelPatches = [
      rec {
        name = patchName "[v7,1/3] dt-bindings: arm: qcom: Add Microsoft Windows Dev Kit 2023";
        patch = pkgs.fetchpatch {
          inherit name;
          url = "https://patches.linaro.org/project/linux-arm-msm/patch/20241101-jg-blackrock-for-upstream-v7-1-8295e9f545d9@oldschoolsolutions.biz/raw";
          hash = "sha256-oNj8qFL7gaiTBHe0gDmIaJnqCasICeB2hdXSCsqFDL4=";
        };
      }
      rec {
        name = patchName "[v7,2/3] firmware: qcom: scm: Allow QSEECOM for Windows Dev Kit 2023";
        patch = pkgs.fetchpatch {
          inherit name;
          url = "https://patches.linaro.org/project/linux-arm-msm/patch/20241101-jg-blackrock-for-upstream-v7-2-8295e9f545d9@oldschoolsolutions.biz/raw";
          hash = "sha256-HXGhcugd3QUcZXP5UhVhzRPSy6goFHgy9gqWqK3jvsg=";
        };
      }
      rec {
        name = patchName "[v7,3/3] arm64: dts: qcom: sc8280xp-blackrock: dt definition for WDK2023";
        patch = pkgs.fetchpatch {
          inherit name;
          url = "https://patches.linaro.org/project/linux-arm-msm/patch/20241101-jg-blackrock-for-upstream-v7-3-8295e9f545d9@oldschoolsolutions.biz/raw";
          hash = "sha256-o2v3zOb3hj9KKvQj4yjdEydorH/KOx2acA+YHHWsRQ8=";
        };
      }
    ];

    boot.initrd.extraFirmwarePaths = map (file: "qcom/sc8280xp/microsoft/blackrock/${file}") [
      "qcadsp8280.mbn"
      "qccdsp8280.mbn"
      "qcdxkmsuc8280.mbn"
    ];

    hardware.deviceTree = {
      enable = true;
      name = "qcom/sc8280xp-microsoft-blackrock.dtb";
    };

    hardware.enableAllHardware = true;

    hardware.firmware = [
      (pkgs.linux-firmware.overrideAttrs (old: {
        postInstall =
          (old.postInstall or "")
          # bash
          + ''
            # symlink exists in armbian/firmware
            pushd $out/lib/firmware/qcom
            ln -sf {a660_gmu.bin,a690_gmu.bin}
            popd

            # copy in updated ath11k wireless firmware
            pushd ${wdk2023_syshacks}/usr/lib/firmware/updates
            find . ! -name '*zst' -type f -exec sh -c 'cp -vf {} $out/lib/firmware/{}' \;
            popd
          '';
      }))
      (pkgs.fetchurl {
        name = "wdk2023-firmware";
        url = "https://github.com/armbian/firmware/archive/8dbb28d2ee8fa3d5f67a9d9dbc64c3d2b3b0adac.tar.gz";
        downloadToTemp = true;
        recursiveHash = true;
        postFetch = ''
          tmp=$(mktemp -d)
          tar -C $tmp -xvf $downloadedFile
          mkdir -p $out/lib/firmware/qcom/sc8280xp/microsoft/blackrock
          cp $tmp/*/qcom/sc8280xp/MICROSOFT/DEVKIT23/* $out/lib/firmware/qcom/sc8280xp/microsoft/blackrock
        '';
        hash = "sha256-b8ohFD3IkS0HFqpSmVg9zN/xofmplgiRgihlJPIaugU";
      })
    ];

    # TODO(jared): pare these down
    boot.initrd.availableKernelModules = [
      "dispcc_sc8280xp"
      "gpio_sbu_mux"
      "gpucc_sc8280xp"
      "i2c_hid_of"
      "i2c_qcom_geni"
      "icc_bwmon"
      "leds_qcom_lpg"
      "lpasscc_sc8280xp"
      "msm"
      "nvme"
      "phy_qcom_apq8064_sata"
      "phy_qcom_edp"
      "phy_qcom_eusb2_repeater"
      "phy_qcom_ipq4019_usb"
      "phy_qcom_ipq806x_sata"
      "phy_qcom_ipq806x_usb"
      "phy_qcom_m31"
      "phy_qcom_pcie2"
      "phy_qcom_qmp_combo"
      "phy_qcom_qmp_pcie"
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
      "pmic_glink_altmode"
      "qcom_glink_smem"
      "qcom_q6v5_pas" # This module loads a lot of FW blobs
      "qcom_rpm"
      "qrtr"
      "uas"
      "ucsi_glink"
      "usb_storage"

      # NOTE: See https://github.com/jhovold/linux/commit/f8ef0dcee4a61f686655f9be82d0576b99612dec

      # storage
      "nvme"
      "pcie_qcom"
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
    ];

    boot.kernelParams = [
      "efi=noruntime"
      "clk_ignore_unused"
      "pd_ignore_unused"
      "arm64.nopauth"
      "iommu.passthrough=0"
      "iommu.strict=0"
      "pcie_aspm.policy=powersupersave"
    ];
  };
}
