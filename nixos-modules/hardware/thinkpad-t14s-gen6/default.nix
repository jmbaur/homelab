{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.hardware.thinkpad-t14s-gen6.enable = mkEnableOption "Lenovo ThinkPad T14s Gen 6";

  config = mkIf config.hardware.thinkpad-t14s-gen6.enable {
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
              version = "6.14.0-rc2";
              extraMeta.branch = "6.14";

              # TODO(jared): remove this
              ignoreConfigErrors = true;

              src = pkgs.fetchFromGitHub {
                owner = "jhovold";
                repo = "linux";
                # wip/x1e80100-6.14-rc2
                rev = "0537e56aaca869dc6e27c16a7105864c769a0345";
                hash = "sha256-3LaUsqRElMley3OAK1v0/MV8m7QTep/Q678Kd7/c47g=";
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
    ];

    boot.initrd.extraFirmwarePaths = map (file: "qcom/${file}") [
      "gen70500_sqe.fw"
      "gen70500_gmu.bin"
    ];

    boot.initrd.includeDefaultModules = false;

    boot.initrd.availableKernelModules = [
      # keyboard
      "i2c_hid_of"
      "i2c_qcom_geni"

      # Definitely needed for USB:
      "usb_storage"
      "phy_qcom_qmp_combo"
      "phy_qcom_snps_eusb2"
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

  };
}
