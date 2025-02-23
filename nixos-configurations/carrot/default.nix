{ lib, ... }:
{
  config = lib.mkMerge [
    { hardware.cn9130-cf-pro.enable = true; }

    {
      custom.server.enable = true;
      custom.basicNetwork.enable = true;
      custom.recovery.targetDisk = "/dev/sda"; # TODO(jared): refine this
    }
  ];
}
