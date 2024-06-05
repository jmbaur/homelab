{ ... }:
{
  nixpkgs.hostPlatform = "aarch64-linux";

  hardware.chromebook.enable = true;

  hardware.deviceTree.name = "mediatek/mt8183-kukui-jacuzzi-fennel14-sku2.dtb";

  tinyboot = {
    enable = true;
    board = "kukui-fennel";
  };

  custom.image = {
    enable = true;
    boot.bootLoaderSpec.enable = true;
    installer.targetDisk = "/dev/mmcblk0"; # TODO(jared): be more specific
  };
}
