{ ... }:
{
  imports = [ ./navidrome.nix ];

  nixpkgs.hostPlatform = "x86_64-linux";

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.chromebook = {
    enable = true;
    laptop = false;
  };

  boot.initrd.availableKernelModules = [
    "nvme"
    "sd_mod"
    "usb_storage"
    "xhci_pci"
  ];
  boot.initrd.kernelModules = [ "i915" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # TODO(jared): This shouldn't be needed, getty-generator should generate this
  # unit on bootup.
  systemd.services."serial-getty@ttyS0" = {
    enable = true;
    wantedBy = [ "getty.target" ];
    serviceConfig.Restart = "always"; # restart when session is closed
  };

  boot.kernelParams = [
    "console=ttyS0,115200"
    "console=tty1" # TODO(jared): needed for some reason?
  ];

  tinyboot = {
    enable = true;
    board = "fizz-fizz";
  };

  custom.wgNetwork.nodes.celery.peer = true;

  custom.server.enable = true;
  custom.basicNetwork.enable = true;

  custom.image = {
    boot.bootLoaderSpec.enable = true;
    installer.targetDisk = "/dev/disk/by-path/pci-0000:03:00.0-nvme-1";
  };
}
