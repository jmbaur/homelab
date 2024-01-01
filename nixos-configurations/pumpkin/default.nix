{ pkgs, ... }: {
  nixpkgs.hostPlatform = "x86_64-linux";

  boot.kernelPackages = pkgs.linuxPackages_latest;
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  hardware.bluetooth.enable = true;

  services.fwupd.enable = true;

  custom = {
    dev.enable = true;
    gui.enable = true;
    image.enable = true;
    image.mutableNixStore = true;
    image.primaryDisk = "/dev/disk/by-path/pci-0000:03:00.0-nvme-1";
    laptop.enable = true;
    users.jared.enable = true;
  };
}
