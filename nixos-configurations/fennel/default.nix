{ lib, ... }: {
  hardware.nvidia-jetpack = {
    enable = true;
    majorVersion = "7";
    som = "thor-agx";
    carrierBoard = "devkit";
  };

  boot.kernelPatches = [
    {
      name = "erofs";
      patch = null;
      structuredExtraConfig = {
        EROFS_FS = lib.kernel.yes;
      };
    }
  ];

  # TODO(jared): doesn't cross
  # hardware.graphics.enable = true;

  users.users.root.initialPassword = "";

  boot.initrd.includeDefaultModules = false;

  # TODO(jared): be more specific
  custom.recovery.targetDisk = "/dev/nvme0n1";
}
