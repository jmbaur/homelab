{ modulesPath, ... }: {
  imports = [
    ../../modules/nixos/depthcharge/sd-image.nix
    "${modulesPath}/profiles/all-hardware.nix"
    "${modulesPath}/profiles/base.nix"
    "${modulesPath}/profiles/installation-device.nix"
  ];
  hardware.kukui-fennel14.enable = true;
  custom.installer.enable = true;
}
