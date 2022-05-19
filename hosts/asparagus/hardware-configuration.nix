# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ] ++ [ "igb" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/1acd4277-8a66-4d11-a38d-8db182261874";
      fsType = "btrfs";
      options = [ "subvol=@" "noatime" "discard=async" "compress=zstd" ];
    };

  boot.initrd.luks.devices."cryptroot" = {
    allowDiscards = true;
    device = "/dev/disk/by-uuid/448d3724-231b-4ba3-bfc5-a46fba7f66d9";
  };

  fileSystems."/nix" =
    {
      device = "/dev/disk/by-uuid/1acd4277-8a66-4d11-a38d-8db182261874";
      fsType = "btrfs";
      options = [ "subvol=@nix" "noatime" "discard=async" "compress=zstd" ];
    };

  fileSystems."/home" =
    {
      device = "/dev/disk/by-uuid/1acd4277-8a66-4d11-a38d-8db182261874";
      fsType = "btrfs";
      options = [ "subvol=@home" "noatime" "discard=async" "compress=zstd" ];
    };

  fileSystems."/home/.snapshots" =
    {
      device = "/dev/disk/by-uuid/1acd4277-8a66-4d11-a38d-8db182261874";
      fsType = "btrfs";
      options = [ "subvol=@home/.snapshots" "noatime" "discard=async" "compress=zstd" ];
    };


  fileSystems."/big" =
    {
      device = "/dev/disk/by-uuid/e4521cb4-61cf-413e-ac12-47cb3a5ec4af";
      fsType = "btrfs";
      options = [ "device=/dev/mapper/cryptbig0" "device=/dev/mapper/cryptbig1" "subvol=@" "autodefrag" "noatime" "compress=zstd" ];
    };

  boot.initrd.luks.devices."cryptbig0".device = "/dev/disk/by-uuid/aa5cb1e1-27ff-4ab7-953f-4daa0c7280b2";
  boot.initrd.luks.devices."cryptbig1".device = "/dev/disk/by-uuid/4d86a90e-bad8-431f-b5ee-84903add4801";

  fileSystems."/big/steam" =
    {
      device = "/dev/disk/by-uuid/e4521cb4-61cf-413e-ac12-47cb3a5ec4af";
      fsType = "btrfs";
      options = [ "device=/dev/mapper/cryptbig0" "device=/dev/mapper/cryptbig1" "subvol=@steam" "autodefrag" "noatime" "compress=zstd" ];
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/BD15-116C";
      fsType = "vfat";
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
