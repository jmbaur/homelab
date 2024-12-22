{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkDefault mkEnableOption mkIf;
in
{
  options.hardware.blackrock.enable = mkEnableOption "microsoft,blackrock";

  config = mkIf config.hardware.blackrock.enable {
    nixpkgs.hostPlatform = mkDefault "aarch64-linux";

    boot.kernelPackages = pkgs.linuxPackages_6_12;

    boot.kernelPatches = [
      {
        name = "WDK2023-dt-definition";
        patch = pkgs.fetchpatch {
          name = "arm64-dts-qcom-sc8280xp-wdk2023-dt-definition-for-WDK2023";
          url = "https://lore.kernel.org/lkml/20240920-jg-blackrock-for-upstream-v2-1-9bf2f1b2191c@oldschoolsolutions.biz/raw";
          hash = "sha256-vntEigchJDzCvR9hapKe7CrhKo1y442NZ/q8+dvUayc=";
        };
      }
      {
        name = "WDK2023-dt-bindings";
        patch = pkgs.fetchpatch {
          name = "dt-bindings-arm-qcom-Add-Microsoft-Windows-Dev-Kit-2023";
          url = "https://lore.kernel.org/lkml/20240920-jg-blackrock-for-upstream-v2-2-9bf2f1b2191c@oldschoolsolutions.biz/raw";
          hash = "sha256-gXGCGUVLch8HjbdUUoL/ga2tbzRLydVKa7hlUeAGB7E=";
        };
      }
    ];

    # TODO(jared): The initrd doesn't include these only because modinfo is not
    # capable of knowing these are needed.
    boot.initrd.prepend = [
      (
        (pkgs.makeInitrdNG {
          name = "initrd-extra-firmware";
          inherit (config.boot.initrd) compressor compressorArgs;
          inherit (config.boot.initrd.systemd) strip;
          contents =
            map
              (file: {
                target = "/lib/firmware/qcom/sc8280xp/MICROSOFT/DEVKIT23/${file}";
                source = "${config.hardware.firmware}/lib/firmware/qcom/sc8280xp/MICROSOFT/DEVKIT23/${file}";
              })
              [
                "qcadsp8280.mbn"
                "qccdsp8280.mbn"
                "qcdxkmsuc8280.mbn"
              ];
        })
        + "/initrd"
      )
    ];

    hardware.deviceTree = {
      enable = true;
      name = "qcom/sc8280xp-microsoft-blackrock.dtb";
    };

    hardware.firmware = [
      pkgs.linux-firmware
      (pkgs.fetchurl {
        name = "wdk2023-firmware";
        url = "https://github.com/armbian/firmware/archive/8dbb28d2ee8fa3d5f67a9d9dbc64c3d2b3b0adac.tar.gz";
        downloadToTemp = true;
        recursiveHash = true;
        postFetch = ''
          tmp=$(mktemp -d)
          tar -C $tmp -xvf $downloadedFile
          mkdir -p $out/lib/firmware/qcom/sc8280xp/MICROSOFT
          cp -r $tmp/*/qcom/sc8280xp/MICROSOFT/DEVKIT23 $out/lib/firmware/qcom/sc8280xp/MICROSOFT
        '';
        hash = "sha256-jkTaIh3hI5KSOlhGS/xzoxnYfzU8t2VXqq5Yv0NqOpw=";
      })
    ];

    boot.initrd.availableKernelModules = [
      "phy_qcom_qmp_pcie"
      "phy_qcom_qmp_combo"
      "qrtr"
      "phy_qcom_edp"
      "gpio_sbu_mux"
      "i2c_hid_of"
      "i2c_qcom_geni"
      "pmic_glink_altmode"
      "leds_qcom_lpg"
      "qcom_q6v5_pas" # This module loads a lot of FW blobs
      "msm"
      "nvme"
      "usb_storage"
      "uas"
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
