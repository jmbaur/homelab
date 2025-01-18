{ ... }:
{
  nixpkgs.hostPlatform = "aarch64-linux";

  hardware.chromebook.enable = true;

  hardware.deviceTree.name = "mediatek/mt8183-kukui-jacuzzi-fennel14-sku2.dtb";

  tinyboot = {
    enable = true;
    board = "kukui-fennel";
  };

  custom.desktop.enable = true;
  custom.dev.enable = true;

  custom.recovery.targetDisk = "/dev/disk/by-path/platform-11230000.mmc";
}
