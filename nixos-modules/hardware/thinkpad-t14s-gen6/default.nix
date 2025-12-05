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

    hardware.firmware = [ pkgs.linux-firmware ];

    boot.kernelPackages = pkgs.linuxPackages_6_18;

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
      # Definitely needed for USB:
      "usb_storage"
      "phy_qcom_qmp_combo"
      "phy_snps_eusb2"
      "phy_qcom_eusb2_repeater"
      "tcsrcc_x1e80100"

      "i2c_hid_of"
      "i2c_qcom_geni"
      "dispcc-x1e80100"
      "gpucc-x1e80100"
      "phy_qcom_edp"
      "panel_edp"
      "msm"
      "nvme"
      "phy_qcom_qmp_pcie"

      # Needed with the DP altmode patches
      "ps883x"
      "pmic_glink_altmode"
      "qrtr"

      # Needed for t14s LCD display
      "pwm_bl"
      "leds_qcom_lpg"

      # Needed for USB
      "phy_nxp_ptn3222"
      "phy_qcom_qmp_usb"
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
