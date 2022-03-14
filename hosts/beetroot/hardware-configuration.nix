# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/e11c1c25-47f4-4daf-9c62-86d425461404";
      fsType = "btrfs";
      options = [ "subvol=@" "noatime" "discard=async" "compress=zstd" ];
    };

  boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-uuid/b110813a-7849-4c8f-bf74-26c1cbe7739f";

  fileSystems."/nix" =
    {
      device = "/dev/disk/by-uuid/e11c1c25-47f4-4daf-9c62-86d425461404";
      fsType = "btrfs";
      options = [ "subvol=@nix" "noatime" "discard=async" "compress=zstd" ];
    };

  fileSystems."/home" =
    {
      device = "/dev/disk/by-uuid/e11c1c25-47f4-4daf-9c62-86d425461404";
      fsType = "btrfs";
      options = [ "subvol=@home" "noatime" "discard=async" "compress=zstd" ];
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/07E2-FCF7";
      fsType = "vfat";
    };

  swapDevices = [ ];
  zramSwap.enable = true;
  zramSwap.swapDevices = 1;

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
