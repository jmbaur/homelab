{ pkgs, ... }:
{
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
    "console=tty0"
  ];

  tinyboot = {
    enable = true;
    board = "fizz-fizz";
  };

  services.navidrome = {
    enable = true;
    settings = {
      Address = "[::]";
      Port = 4533;
    };
  };

  users.users.root.openssh.authorizedKeys.keyFiles = [ pkgs.jmbaur-ssh-keys ];

  custom.basicNetwork.enable = true;

  custom.server.enable = true;

  custom.image = {
    enable = true;
    mutableNixStore = true; # TODO(jared): make false
    boot.bootLoaderSpec.enable = true;
    installer.targetDisk = "/dev/nvme0n1"; # TODO(jared): be more specific
  };
}
