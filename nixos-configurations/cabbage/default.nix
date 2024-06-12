{ ... }:
{
  nixpkgs.hostPlatform = "x86_64-linux";

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.chromebook.enable = true;

  boot.initrd.availableKernelModules = [
    "nvme"
    "sd_mod"
    "usb_storage"
    "xhci_pci"
  ];
  boot.initrd.kernelModules = [ "i915" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  custom.desktop.enable = true;

  tinyboot = {
    enable = true;
    board = "volteer-elemi";
  };

  custom.image = {
    boot.bootLoaderSpec.enable = true;
    installer.targetDisk = "/dev/disk/by-path/pci-0000:03:00.0-nvme-1";
  };
}
