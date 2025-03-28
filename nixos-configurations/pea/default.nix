{
  lib,
  ...
}:

{
  config = lib.mkMerge [
    {
      hardware.chromebook.asurada-spherion.enable = true;

      # TODO(jared): resolve conflict between systemd-boot and tinyboot.
      boot.loader.systemd-boot.enable = false;

      tinyboot = {
        enable = true;
        platform.mediatek = true;
        video = true;
        chromebook = true;
      };
    }
    {
      custom.desktop.enable = true;
      custom.dev.enable = true;
      custom.recovery.targetDisk = "/dev/mmcblk0"; # TODO(jared): refine this
    }
  ];
}
