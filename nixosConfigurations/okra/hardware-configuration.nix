# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/d8063802-74df-4bb6-9c49-31990a305378";
      fsType = "btrfs";
      options = [ "subvol=@" ];
    };

  boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-uuid/982ae5ce-3090-4fad-8e3e-b0f3339387ee";

  fileSystems."/nix" =
    { device = "/dev/disk/by-uuid/d8063802-74df-4bb6-9c49-31990a305378";
      fsType = "btrfs";
      options = [ "subvol=@nix" ];
    };

  fileSystems."/home" =
    { device = "/dev/disk/by-uuid/d8063802-74df-4bb6-9c49-31990a305378";
      fsType = "btrfs";
      options = [ "subvol=@home" ];
    };

  fileSystems."/home/.snapshots" =
    { device = "/dev/disk/by-uuid/d8063802-74df-4bb6-9c49-31990a305378";
      fsType = "btrfs";
      options = [ "subvol=@home/.snapshots" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/8B86-EBBD";
      fsType = "vfat";
    };

  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno1.useDHCP = lib.mkDefault true;
  # networking.interfaces.wg-work.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp0s20f3.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  # high-resolution display
  hardware.video.hidpi.enable = lib.mkDefault true;
}
