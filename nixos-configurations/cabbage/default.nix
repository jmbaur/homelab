{ lib, pkgs, ... }: {
  nixpkgs.hostPlatform = "x86_64-linux";

  boot.kernelPackages = pkgs.linuxPackages_latest;
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.chromebook.enable = true;

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  custom.users.jared.enable = true;

  boot.initrd.systemd.emergencyAccess = lib.warn "initrd emergency access enabled" true;

  custom.image = {
    enable = true;
    mutableNixStore = true;
    bootloaderspec.enable = true;
    primaryDisk = "/dev/disk/by-path/pci-0000:03:00.0-nvme-1";
  };
}
