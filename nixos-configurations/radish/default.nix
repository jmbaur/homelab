{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    "${modulesPath}/hardware/cpu/intel-npu.nix"
    "${modulesPath}/installer/scan/not-detected.nix"
  ];

  config = lib.mkMerge [
    {
      nixpkgs.hostPlatform = "x86_64-linux";

      boot.initrd.availableKernelModules = [
        "xhci_pci"
        "thunderbolt"
        "nvme"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-intel" ];
      boot.extraModulePackages = [ ];

      hardware.cpu.intel.npu.enable = true;
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    }
    {
      custom.dev.enable = true;
      custom.desktop.enable = true;
      custom.recovery.targetDisk = "/dev/disk/by-path/pci-0000:01:00.0-nvme-1";
      custom.backup.sender.enable = false;
      services.yggdrasil.enable = false;

      services.cloudflare-warp.enable = true;
      nixpkgs.config.allowUnfree = true;

      virtualisation.podman.enable = true;
    }
  ];
}
