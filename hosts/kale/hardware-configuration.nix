# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "igb" "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/8741fae3-808c-4376-838c-1e90dbc50ff8";
      fsType = "btrfs";
      options = [ "subvol=@" "noatime" "compress=zstd" "discard=async" ];
    };

  boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-uuid/d27a75ca-474f-4859-a608-cb2859f98cd9";

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/2D8C-C352";
      fsType = "vfat";
    };

  fileSystems."/nix" =
    {
      device = "/dev/disk/by-uuid/8741fae3-808c-4376-838c-1e90dbc50ff8";
      fsType = "btrfs";
      options = [ "subvol=@nix" "noatime" "compress=zstd" "discard=async" ];
    };

  fileSystems."/home" =
    {
      device = "/dev/disk/by-uuid/8741fae3-808c-4376-838c-1e90dbc50ff8";
      fsType = "btrfs";
      options = [ "subvol=@home" "noatime" "compress=zstd" "discard=async" ];
    };

  swapDevices = [ ];
  zramSwap = {
    enable = true;
    swapDevices = 1;
  };

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  # high-resolution display
  hardware.video.hidpi.enable = lib.mkDefault true;
}
