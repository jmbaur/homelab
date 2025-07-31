{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf versions;
in
{
  options.hardware.thinkpad-t14s-gen6.enable = mkEnableOption "Lenovo ThinkPad T14s Gen 6";

  config = mkIf config.hardware.thinkpad-t14s-gen6.enable {
    hardware.qualcomm.enable = true;

    nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

    hardware.deviceTree.name = "qcom/x1e78100-lenovo-thinkpad-t14s.dtb";

    hardware.firmware = [ pkgs.linux-firmware ];

    boot.kernelPackages = pkgs.linuxPackagesFor (
      pkgs.callPackage
        (
          { buildLinux, ... }@args:
          buildLinux (
            args
            // rec {
              version = "6.16.0";
              extraMeta.branch = versions.majorMinor version;

              # TODO(jared): remove this
              ignoreConfigErrors = true;

              src = pkgs.fetchFromGitHub {
                owner = "jhovold";
                repo = "linux";
                # wip/x1e80100-6.16
                rev = "a9cd6cda46ab81b1ec1d687d40ff0933dc6e6915";
                hash = "sha256-pEnaEqHID9+ar+qCzygtGGneajYcBdWACEd1CIzPdM0=";
              };
              kernelPatches = (args.kernelPatches or [ ]);
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
      "console=tty1"
    ];

    boot.initrd.extraFirmwarePaths = map (file: "qcom/${file}") [
      "gen70500_sqe.fw"
      "gen70500_gmu.bin"
      "x1e80100/LENOVO/21N1/qcdxkmsuc8380.mbn"
    ];

    boot.initrd.includeDefaultModules = false;

    boot.initrd.availableKernelModules = [
      # keyboard
      "i2c_hid_of"
      "i2c_qcom_geni"

      # Definitely needed for USB:
      "uas"
      "phy_qcom_qmp_combo"
      "phy_snps_eusb2"
      "phy_qcom_eusb2_repeater"
      "tcsrcc_x1e80100"

      "dispcc-x1e80100"
      "gpucc-x1e80100"
      "phy_qcom_edp"
      "panel_edp"
      "msm"
      "nvme"
      "phy_qcom_qmp_pcie"
      "pcie_qcom"
      "panel_samsung_atna33xc20"

      "qcom_pmic_tcpm"
      "phy-qcom-qmp-usb"
      "phy-qcom-qmp-usbc"

      # Needed with the DP altmode patches
      "ps883x"
      "pmic_glink_altmode"
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

    boot.loader.efi.canTouchEfiVariables = false;

    services.evremap.settings.device_name = "hid-over-i2c 04F3:000D Keyboard";

    # https://lists.infradead.org/pipermail/ath12k/2024-April/002004.html
    networking.wireless.iwd.settings.General.ControlPortOverNL80211 = false;

    environment.systemPackages = [
      (pkgs.writeShellApplication {
        name = "update-firmware";
        runtimeInputs = [
          config.systemd.package
          pkgs.innoextract
        ];
        text = ''
          declare -r esp=${config.boot.loader.efi.efiSysMountPoint}
          ${lib.fileContents ./update-firmware.bash}
        '';
      })
    ];
  };
}
