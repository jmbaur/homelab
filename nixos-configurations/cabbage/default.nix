{ pkgs, ... }:
{
  nixpkgs.hostPlatform = "x86_64-linux";

  boot.kernelPackages = pkgs.linuxPackages_latest;
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.chromebook.enable = true;

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  custom.image = {
    enable = true;
    mutableNixStore = true;
    boot.uefi.enable = true;
    # boot.bootLoaderSpec.enable = true;
    installer.targetDisk = "/dev/disk/by-path/pci-0000:03:00.0-nvme-1";
  };

  ##############################################################################
  boot.initrd.systemd = {
    managerEnvironment.SYSTEMD_LOG_LEVEL = "debug";
    services.systemd-repart.environment.SYSTEMD_LOG_LEVEL = "debug";
  };
}
