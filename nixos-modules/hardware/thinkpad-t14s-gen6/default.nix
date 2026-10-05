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

    # Not using EL2 (via slbounce), since on this machine linux can't start
    # the full adsp firmware from EL2, which means no audio.
    hardware.deviceTree.name = "qcom/x1e78100-lenovo-thinkpad-t14s.dtb";

    hardware.firmware = [ pkgs.linux-firmware ];

    boot.kernelPackages = pkgs.linuxPackages_7_2;

    boot.kernelPatches = [
      {
        # Mainline leaves the bluetooth UART disabled on the t14s.
        name = "t14s-bluetooth";
        patch = ./0001-arm64-dts-qcom-x1e78100-t14s-add-WCN7850-Bluetooth.patch;
      }
      {
        # Iris faults (and wedges until reboot) when a non-pixel buffer lands
        # below 600MB of IOVA. Backport of
        # https://patchwork.linuxtv.org/project/linux-media/patch/20260818-reserve_iova_in_driver-v2-1-5005a1154408@oss.qualcomm.com/
        name = "iris-reserve-low-iova";
        patch = ./0002-media-iris-Fix-iova-allocation-from-restrict-region.patch;
      }
    ];

    boot.consoleLogLevel = 7;

    boot.kernelParams = [
      "cma=128M" # used on ubuntu
      "efi=noruntime" # used on ubuntu, efivars are provided by qcom_qseecom_uefisecapp
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
      "uas"
      "phy_qcom_qmp_combo"
      "phy_snps_eusb2"
      "phy_qcom_eusb2_repeater"

      "i2c_hid_of"
      "i2c_qcom_geni"
      "dispcc-x1e80100"
      "gpucc-x1e80100"
      "phy_qcom_edp"
      "panel_edp"
      "msm"
      "nvme"
      "phy_qcom_qmp_pcie"

      # The HDMI port's bridge chain, msm won't bind without it
      "display_connector"
      "simple_bridge"

      # The USB-C ports' DP bridge chain (retimers + HPD), msm won't bind
      # without it. qrtr isn't a symbol dependency, but pmic_glink can't probe
      # without it.
      "ps883x"
      "pmic_glink_altmode"
      "qrtr"

      # Needed for t14s LCD display
      "pwm_bl"
      "leds_qcom_lpg"

      # Needed for USB
      "phy_nxp_ptn3222"
      "phy_qcom_qmp_usb"

      # realtime clock, prevent time jumps
      "rtc_pm8xxx"
    ];

    # TODO(jared): fix this
    systemd.tpm2.enable = false;
    boot.initrd.systemd.tpm2.enable = false;
    custom.recovery.extraModule.imports = [
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
