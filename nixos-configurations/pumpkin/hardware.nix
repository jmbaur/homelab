{ config, pkgs, ... }: {
  imports = [ (import ../disko-single-disk-encrypted.nix "/dev/nvme0n1") ];

  nixpkgs.hostPlatform = "x86_64-linux";

  zramSwap.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];
}
