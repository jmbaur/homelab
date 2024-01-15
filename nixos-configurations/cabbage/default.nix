{ pkgs, ... }: {
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

  custom.image = {
    enable = true;
    bootVariant = "bootloaderspec";
    mutableNixStore = true;
    primaryDisk = "/dev/disk/by-path/pci-0000:03:00.0-nvme-1";
  };
}
