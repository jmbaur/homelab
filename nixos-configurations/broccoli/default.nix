{ ... }:
{
  hardware.blackrock.enable = true;
  custom.desktop.enable = true;
  custom.dev.enable = true;
  custom.recovery.targetDisk = "/dev/disk/by-path/platform-1c20000.pcie-pci-0002:01:00.0-nvme-1";

  # TODO(jared): doesn't work on wdk2023?
  systemd.services.pd-mapper.enable = false;
}
