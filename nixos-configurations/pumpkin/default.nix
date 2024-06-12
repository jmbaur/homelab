{ pkgs, ... }:
{
  nixpkgs.hostPlatform = "x86_64-linux";

  boot.kernelPackages = pkgs.linuxPackages_latest;
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  custom = {
    dev.enable = true;
    desktop.enable = true;
    wgNetwork.nodes.celery = {
      enable = true;
      hostname = "celery.jmbaur.com";
    };
    image = {
      hasTpm2 = true;
      mutableNixStore = true;
      boot.uefi.enable = true;
      installer.targetDisk = "/dev/disk/by-path/pci-0000:03:00.0-nvme-1";
    };
  };
}
