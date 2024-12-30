{ pkgs, ... }:
{
  nixpkgs.hostPlatform = "aarch64-linux";

  boot.kernelPackages = pkgs.linuxPackages_6_12;

  hardware.deviceTree.name = "qcom/x1e78100-lenovo-thinkpad-t14s.dtb";
  hardware.enableRedistributableFirmware = true;

  custom.dev.enable = true;
  custom.desktop.enable = true;
  custom.image = {
    boot.uefi.enable = true;
    installer.targetDisk = "/dev/nvme0n1";
  };
}
