{ pkgs, ... }:
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

  boot.kernelPackages = pkgs.linuxPackages_6_12;

  tinyboot = {
    enable = false;
    board = "brya-banshee";
  };

  custom.desktop.enable = true;
  custom.dev.enable = true;
  custom.recovery.targetDisk = "/dev/disk/by-path/pci-0000:01:00.0-nvme-1";

  services.tinc.networks.jmbaur = {
    settings = {
      ConnectTo = "squash";
    };
  };
}
