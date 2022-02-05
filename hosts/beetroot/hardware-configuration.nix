# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/ba7def78-16e5-4a70-8eca-2e16b3ec69de";
      fsType = "btrfs";
      options = [ "subvol=@" "noatime" "compress=zstd" "discard=async" ];
    };

  boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-uuid/433cdbe9-79ba-4353-b374-0cbd07a151f9";

  fileSystems."/.snapshots" =
    {
      device = "/dev/disk/by-uuid/ba7def78-16e5-4a70-8eca-2e16b3ec69de";
      fsType = "btrfs";
      options = [ "subvol=@snapshots" "noatime" "compress=zstd" "discard=async" ];
    };

  fileSystems."/home" =
    {
      device = "/dev/disk/by-uuid/ba7def78-16e5-4a70-8eca-2e16b3ec69de";
      fsType = "btrfs";
      options = [ "subvol=@home" "noatime" "compress=zstd" "discard=async" ];
    };

  fileSystems."/home/.snapshots" =
    {
      device = "/dev/disk/by-uuid/ba7def78-16e5-4a70-8eca-2e16b3ec69de";
      fsType = "btrfs";
      options = [ "subvol=@home/snapshots" "noatime" "compress=zstd" "discard=async" ];
    };

  fileSystems."/nix" =
    {
      device = "/dev/disk/by-uuid/ba7def78-16e5-4a70-8eca-2e16b3ec69de";
      fsType = "btrfs";
      options = [ "subvol=@nix" "noatime" "compress=zstd" "discard=async" ];
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/2E16-F769";
      fsType = "vfat";
    };

  swapDevices = [ ];
  zramSwap = {
    enable = true;
    swapDevices = 1;
  };

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
