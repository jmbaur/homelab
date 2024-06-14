{ pkgs, ... }:
{
  imports = [
    ./navidrome.nix
    ./updates.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.chromebook.enable = true;

  boot.initrd.availableKernelModules = [
    "nvme"
    "sd_mod"
    "usb_storage"
    "xhci_pci"
  ];
  boot.initrd.kernelModules = [ "i915" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  boot.kernelParams = [
    "console=ttyS0,115200"
    "console=tty0" # TODO(jared): this shouldn't be needed
  ];

  tinyboot = {
    enable = true;
    board = "fizz-fizz";
  };

  custom.wgNetwork.nodes.celery.enable = true;

  custom.server.enable = true;

  custom.image = {
    mutableNixStore = true; # TODO(jared): make false
    boot.bootLoaderSpec.enable = true;
    installer.targetDisk = "/dev/disk/by-path/pci-0000:03:00.0-nvme-1";
  };
}
