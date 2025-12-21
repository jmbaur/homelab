{ lib, pkgs, ... }:
{
  config = lib.mkMerge [
    {
      nixpkgs.hostPlatform = "x86_64-linux";
      hardware.cpu.amd.updateMicrocode = true;
      hardware.enableRedistributableFirmware = true;

      boot.initrd.availableKernelModules = [
        "nvme"
        "sd_mod"
        "uas"
        "xhci_pci"
        "ahci"
        "usbhid"
        "r8169" # ethernet controller on motherboard
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-amd" ];
      boot.extraModulePackages = [ ];

      hardware.firmware = [ pkgs.linux-firmware ];

      boot.kernelParams = [ "console=ttyS0,115200" ];
    }
    {
      services.fwupd.enable = true;
      custom.server.enable = true;
      custom.basicNetwork.enable = true;
      custom.recovery.targetDisk = "/dev/disk/by-path/pci-0000:01:00.0-nvme-1";
    }
  ];
}
