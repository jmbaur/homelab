{
  config,
  lib,
  ...
}:

let
  inherit (lib) mkDefault mkEnableOption mkIf;
in
{
  options.hardware.kukui-fennel14 = {
    enable = mkEnableOption "google kukui-fennel14 board";
  };
  config = mkIf config.hardware.kukui-fennel14.enable {
    nixpkgs.hostPlatform = mkDefault "aarch64-linux";

    hardware.chromebook.enable = true;
    hardware.enableRedistributableFirmware = true;
    hardware.deviceTree = {
      enable = true;
      filter = "mt8183-kukui-jacuzzi-fennel14*.dtb";
    };
  };
}
