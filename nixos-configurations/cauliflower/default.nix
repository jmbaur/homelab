{
  config,
  pkgs,
  lib,
  ...
}:
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

  boot.kernelPackages = pkgs.linuxPackages_latest;

  system.build.firmware = pkgs.buildCoreboot {
    kconfig = ''
      CONFIG_BOARD_GOOGLE_BANSHEE=y
      CONFIG_VENDOR_GOOGLE=y
      CONFIG_GENERIC_LINEAR_FRAMEBUFFER=y
      CONFIG_CBFS_SIZE=0x800000
      CONFIG_PAYLOAD_LINUX=y
      CONFIG_PAYLOAD_FILE="${config.tinyboot.build.linux}/bzImage"
      CONFIG_LINUX_INITRD="${config.tinyboot.build.initrd}/tboot-loader.cpio"
    '';
  };

  # TODO(jared): fix this
  boot.initrd.systemd.tpm2.enable = false;

  boot.loader.systemd-boot.enable = false;
  tinyboot = {
    enable = true;
    chromebook = true;
    efi = true; # coreboot exposes an efi-compatible framebuffer
    linux.consoles = [
      "ttyS0,115200n8"
      "tty1"
    ];
    linux.kconfig = with lib.kernel; {
      PINCTRL_ALDERLAKE = yes;
      PINCTRL_TIGERLAKE = yes;
    };
  };

  services.yggdrasil.settings.Peers = [ "tls://celery.jmbaur.com:443" ];

  custom.desktop.enable = true;
  custom.dev.enable = true;
  nixpkgs.buildPlatform = config.nixpkgs.hostPlatform;
  custom.recovery.targetDisk = "/dev/disk/by-path/pci-0000:01:00.0-nvme-1";

  services.pipewire.wireplumber.configPackages = [
    (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/10-pro-audio.conf" ''
      monitor.alsa.rules = [
        {
          matches = [
            {
              device.name = "alsa_card.pci-0000_00_1f.3-platform-adl_rt5682_def"
            }
          ]
          actions = {
            update-props = {
              device.profile = "pro-audio"
              priority.session = 600
              priority.driver = 600
            }
          }
        }
      ]
    '')
  ];

}
