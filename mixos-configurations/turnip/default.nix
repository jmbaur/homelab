inputs:

{ pkgs, lib, ... }:
{
  nixpkgs.pkgs = import inputs.nixpkgs {
    localSystem = "x86_64-linux";
    crossSystem = {
      isStatic = false;
      config = "armv7l-unknown-linux-gnueabihf";
      gcc = {
        arch = "armv7-a";
        fpu = "vfpv3-d16";
      };
    };
  };

  packages = [
    pkgs.kexec-tools
    pkgs.strace
  ];

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
      patch = ./0001-hwrng-rng90-Add-Microchip-RNG90-driver.patch;
      structuredExtraConfig = {
        HW_RANDOM_RNG90 = lib.kernel.module;
      };
    }
  ];
}
