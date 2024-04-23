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

  hardware.bluetooth.enable = true;
  networking.wireless.iwd.enable = true;

  services.fwupd.enable = true;

  custom = {
    dev.enable = true;
    desktop.enable = true;
  };

  custom.image = {
    enable = true;
    hasTpm2 = true;
    mutableNixStore = true;
    boot.uefi.enable = true;
    primaryDisk = "/dev/disk/by-path/pci-0000:03:00.0-nvme-1";
  };

  # For debugging why systemd-repart doesn't seem to work well on this one
  # device.
  boot.initrd.systemd.emergencyAccess = true;
  boot.initrd.systemd.managerEnvironment.SYSTEMD_LOG_LEVEL = "debug";
  boot.initrd.systemd.services.systemd-repart.environment.SYSTEMD_LOG_LEVEL = "debug";
}
