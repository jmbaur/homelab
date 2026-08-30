{ pkgs, lib, ... }: {
  init.shell = {
    tty = "ttyS0";
    action = "askfirst";
    process = "/bin/sh";
  };

  boot.kernelPackages = pkgs.linuxPackagesFor (
    pkgs.buildLinux {
      inherit (pkgs.linux_7_2) version src;
      autoModules = true;
      preferBuiltin = true;
      buildDTBs = true;
      target = "zImage";
      defconfig = "mvebu_v7_defconfig";
    }
  );

  boot.kernelPatches = [
    {
      name = "efi-support";
      patch = null;
      structuredExtraConfig = {
        EFI = lib.kernel.yes;
        EFI_STUB = lib.kernel.yes;
      };
    }
    # mvebu_v7_defconfig does not enable kexec, maybe because of this:
    # https://github.com/gregkh/linux/blob/7b923c78b50d2ec52690c4353e5aad8302e80599/arch/arm/mach-mvebu/pmsu.c#L507
    {
      name = "kexec-support";
      # Manual revert of https://patchwork.kernel.org/project/linux-arm-kernel/patch/1427820378-13415-1-git-send-email-gregory.clement@free-electrons.com/
      patch = ./cpuidle.patch;
      structuredExtraConfig = {
        KEXEC = lib.kernel.yes;
      };
    }
    {
      name = "rng90-support";
      patch = ./0001-char-hw_random-add-RNG90-driver.patch;
      structuredExtraConfig = {
        HW_RANDOM_RNG90 = lib.kernel.module;
      };
    }
    {
      name = "modules-decompress";
      patch = null;
      structuredExtraConfig = {
        MODULES_DECOMPRESS = lib.kernel.yes;
      };
    }
  ];
}
