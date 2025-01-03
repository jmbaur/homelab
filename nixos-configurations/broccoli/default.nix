{
  hardware.blackrock.enable = true;
  custom.basicNetwork.enable = true;
  custom.desktop.enable = false;
  custom.dev.enable = true;
  custom.normalUser.enable = false;
  users.users.root.initialPassword = "root";
  custom.image = {
    boot.uefi.enable = true;
    installer.targetDisk = "/dev/nvme0n1";
  };
}
