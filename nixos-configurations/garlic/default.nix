{
  hardware.thinkpad-t14s-gen6.enable = true;
  # custom.dev.enable = true;
  # custom.desktop.enable = true;
  custom.recovery.targetDisk = "/dev/disk/by-path/platform-1bf8000.pci-pci-0006:01:00.0-nvme-1";
  nixpkgs.buildPlatform = "x86_64-linux";
}
