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
  custom.dev.enable = true;

  tinyboot = {
    enable = false;
    board = "brya-banshee";
  };

  custom.image = {
    enable = true;
    mutableNixStore = true;
    boot.uefi.enable = true;
    installer.targetDisk = "/dev/nvme0n1";
  };
}
