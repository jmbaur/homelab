{ lib, ... }:
{
  config = lib.mkMerge [
    {
      hardware.blackrock.enable = true;
      custom.desktop.enable = false;
      custom.dev.enable = true;
      custom.basicNetwork.enable = true;
      custom.normalUser.enable = false;
      custom.image = {
        boot.uefi.enable = true;
        installer.targetDisk = "/dev/nvme0n1";
      };
    }
    # TODO(jared): delete this
    {
      users.users.root.initialPassword = "root";
      services.homed.enable = true;
      networking.wireless.iwd.enable = true;
    }
  ];
}
