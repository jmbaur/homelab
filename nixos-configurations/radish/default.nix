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
      custom.basicNetwork.enable = true;
      custom.common.enable = true;
      custom.dev.enable = true;
      custom.desktop.enable = true;

      services.cloudflare-warp.enable = true;
      nixpkgs.config.allowUnfree = true;
    }
  ];
}
