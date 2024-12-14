{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkDefault mkEnableOption mkIf;
in
{
  options.hardware.blackrock.enable = mkEnableOption "microsoft,blackrock";

  config = mkIf config.hardware.blackrock.enable {
    nixpkgs.hostPlatform = mkDefault "aarch64-linux";

    boot.kernelPackages = pkgs.linuxPackages_6_12;

    boot.kernelPatches = [
      {
        name = "WDK2023-dt-definition";
        patch = pkgs.fetchpatch {
          name = "arm64-dts-qcom-sc8280xp-wdk2023-dt-definition-for-WDK2023";
          url = "https://lore.kernel.org/lkml/20240920-jg-blackrock-for-upstream-v2-1-9bf2f1b2191c@oldschoolsolutions.biz/raw";
          hash = "sha256-vntEigchJDzCvR9hapKe7CrhKo1y442NZ/q8+dvUayc=";
        };
      }
      {
        name = "WDK2023-dt-bindings";
        patch = pkgs.fetchpatch {
          name = "dt-bindings-arm-qcom-Add-Microsoft-Windows-Dev-Kit-2023";
          url = "https://lore.kernel.org/lkml/20240920-jg-blackrock-for-upstream-v2-2-9bf2f1b2191c@oldschoolsolutions.biz/raw";
          hash = "sha256-gXGCGUVLch8HjbdUUoL/ga2tbzRLydVKa7hlUeAGB7E=";
        };
      }
    ];

    hardware.deviceTree = {
      enable = true;
      name = "qcom/sc8280xp-microsoft-blackrock.dtb";
    };
  };
}
