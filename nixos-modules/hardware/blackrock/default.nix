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

    boot.kernelPackages = pkgs.linuxPackages_testing;

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
      (pkgs.linux-firmware.overrideAttrs (old: {
        postInstall =
          (old.postInstall or "")
          # bash
          + ''
            pushd ${wdk2023_syshacks}/usr/lib/firmware/updates
            find . ! -name '*zst' -type f -exec sh -c 'cp -vf {} $out/lib/firmware/{}' \;
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
