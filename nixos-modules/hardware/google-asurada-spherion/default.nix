{
  config,
  lib,
  ...
}:

let
  inherit (lib)
    mkDefault
    mkEnableOption
    mkIf
    ;
in
{
  options.hardware.chromebook.asurada-spherion = {
    enable = mkEnableOption "google asurada-spherion board";
  };

  config = mkIf config.hardware.chromebook.asurada-spherion.enable {
    nixpkgs.hostPlatform = mkDefault "aarch64-linux";

    hardware.chromebook.enable = true;

    hardware.enableRedistributableFirmware = true;

    hardware.deviceTree.name = "mediatek/mt8192-asurada-spherion-r0.dtb";

    boot.kernelParams = [
      "console=ttyS0,115200"
      "console=tty1"
    ];
  };
}
