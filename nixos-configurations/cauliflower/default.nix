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
  custom.image = {
    boot.uefi.enable = true;
    installer.targetDisk = "/dev/nvme0n1";
  };

  services.ttyd = {
    enable = true;
    enableIPv6 = true;
    writeable = true;
    clientOptions.theme = builtins.toJSON { background = "black"; };
  };
}
