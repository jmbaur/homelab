{ lib, pkgs, ... }:
{
  imports = [
    ./builds.nix
  ];

  config = lib.mkMerge [
    {
      nixpkgs.hostPlatform = "x86_64-linux";
      hardware.cpu.amd.updateMicrocode = true;
      hardware.enableRedistributableFirmware = true;

      # latest stable
      boot.kernelPackages = pkgs.linuxPackages_6_10;

      boot.initrd.availableKernelModules = [
        "nvme"
        "sd_mod"
        "usb_storage"
        "xhci_pci"
        "ahci"
        "usbhid"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-amd" ];
      boot.extraModulePackages = [ ];

      hardware.firmware = [ pkgs.linux-firmware ];

      boot.kernelParams = [
        "console=ttyS0,115200"
        "console=tty1" # TODO(jared): remove this when server is headless
      ];
    }
    {
      services.fwupd.enable = true;
      custom.server.enable = true;
      custom.basicNetwork.enable = true;
      custom.image = {
        mutableNixStore = true; # TODO(jared): make false
        boot.uefi.enable = true;
        installer.targetDisk = "/dev/disk/by-path/pci-0000:01:00.0-nvme-1";
        hasTpm2 = true;
      };
    }
  ];
}
