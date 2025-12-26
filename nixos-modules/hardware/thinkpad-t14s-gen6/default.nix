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
      "uas"
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

      # realtime clock, prevent time jumps
      "rtc_pm8xxx"
    ];

    # TODO(jared): fix this
    systemd.tpm2.enable = false;
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

    boot.loader.systemd-boot.extraFiles = {
      "tcblaunch.exe" = pkgs.fetchurl {
        url = "https://vsblobprodscussu5shard90.blob.core.windows.net/b-4712e0edc5a240eabf23330d7df68e77/4F9B2982937F4B7FC56DBBD667745F4F0FF8FA71561CD8684A2902159CA3FC0100.blob?sv=2019-07-07&sr=b&sig=pe6b74jGunCMhOHfkQQNll5rth0zLyeAAToScISlaGs%3D&skoid=4866d8d7-57cb-4216-997d-bade18bdbe68&sktid=33e01921-4d64-4f8c-a055-5bdaffd5e33d&skt=2025-12-26T03%3A45%3A26Z&ske=2025-12-28T04%3A45%3A26Z&sks=b&skv=2019-07-07&se=2025-12-27T06%3A18%3A38Z&sp=r&rscl=x-e2eid-fac63bd0-d5f74adf-bb992798-5cff52f2-session-3a8a353c-4b2c41d9-a9a9d47f-0e3d286b"; # TODO(jared): no idea if this is permalink-ish
        hash = "sha256-XfzQJTtu6ZSZqzPKwiHoqc6kfz/fbU4R3pqfPEdw0D0=";
      };
      # "EFI/systemd/drivers/slbounceaa64.efi" = "${pkgs.slbounce}/slbounce.efi";
      "slbounce.efi" = "${pkgs.slbounce}/slbounce.efi";
      "dtbhack.efi" = "${pkgs.slbounce}/dtbhack.efi";
      "sltest.efi" = "${pkgs.slbounce}/sltest.efi";
    };
  };
}
