{ ... }:
{
  hardware.blackrock.enable = true;
  custom.desktop.enable = false;
  custom.dev.enable = true;
  custom.image = {
    boot.uefi.enable = true;
    installer.targetDisk = "/dev/nvme0n1";
  };
}
