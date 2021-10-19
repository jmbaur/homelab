# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  boot.initrd.luks = {
    gpgSupport = true;
    devices.cryptlvm = {
      allowDiscards = true;
      device = "/dev/disk/by-uuid/1ced5915-7dd2-4bbb-90cd-b2e48c605286";
      preLVM = true;
      gpgCard = {
        publicKey = ../../lib/pgp_keys.asc;
        encryptedPass = ./disk.key.gpg;
        gracePeriod = 30;
      };
    };
  };

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/88f3f518-27ab-4b6b-b658-d33c9f7caf8c";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/9D34-F1F0";
      fsType = "vfat";
    };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/568b470c-9f32-4f35-9150-b35b1eb8c860"; }];

}

