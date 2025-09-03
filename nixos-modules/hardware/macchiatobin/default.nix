{
  config,
  lib,
  pkgs,
  ...
}:

let
  # The final flash-image.bin firmware image ends up being ~1.6MiB, so we
  # need to change the default offset of the uboot environment to
  # accommodate this.
  envOffset = "0x200000";
in
{
  options.hardware.macchiatobin.enable = lib.mkEnableOption "macchiatobin hardware support";

  config = lib.mkIf config.hardware.macchiatobin.enable {
    nixpkgs.hostPlatform = "aarch64-linux";
    nixpkgs.buildPlatform = "x86_64-linux";

    hardware.deviceTree.name = "marvell/armada-8040-mcbin.dtb";
    system.build.firmware = pkgs.mcbin-firmware.override {
      uboot = pkgs.makeUBoot {
        boardName = "mvebu_mcbin-88f8040";
        artifacts = [ "u-boot.bin" ];
        meta.platforms = [ "aarch64-linux" ];
        kconfig = with lib.kernel; {
          DISTRO_DEFAULTS = unset;
          BOOTSTD_DEFAULTS = yes;

          # Allow for using u-boot scripts.
          BOOTSTD_FULL = yes;

          # Allow for larger than the default 8MiB kernel size
          SYS_BOOTM_LEN = freeform "0x${lib.toHexString (64 * 1024 * 1024)}"; # 64MiB

          ENV_OFFSET = freeform envOffset;

          USE_PREBOOT = yes;
          PREBOOT = freeform "pci enum; usb start; nvme scan";
        };
      };
    };

    hardware.firmware = [ (pkgs.extractLinuxFirmwareDirectory "inside-secure") ];

    environment.systemPackages = [
      pkgs.uboot-env-tools
      pkgs.mtdutils
      (pkgs.writeShellScriptBin "update-firmware" ''
        ${lib.getExe' pkgs.mtdutils "flashcp"} \
          --verbose \
          ${config.system.build.firmware}/flash-image.bin \
          /dev/mtd0
      '')
    ];

    environment.etc."fw_env.config".text = ''
      /dev/mtd0 ${envOffset} 0x10000 0x10000
    '';
  };
}
