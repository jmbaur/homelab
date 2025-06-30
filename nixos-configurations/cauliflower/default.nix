{
  config,
  pkgs,
  ...
}:

let
  tinybootKernel = pkgs.linuxKernel.manualConfig {
    inherit (pkgs.linux_6_15) src version;
    configfile = ./tinyboot-linux.config;
  };
in
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

  system.build.firmware = pkgs.buildCoreboot {
    kconfig = ''
      CONFIG_BOARD_GOOGLE_BANSHEE=y
      CONFIG_VENDOR_GOOGLE=y
      CONFIG_GENERIC_LINEAR_FRAMEBUFFER=y
      CONFIG_CBFS_SIZE=0x800000
      CONFIG_PAYLOAD_LINUX=y
      CONFIG_PAYLOAD_FILE="${tinybootKernel}/bzImage"
      CONFIG_LINUX_INITRD="${pkgs.tinyboot}/${pkgs.tinyboot.initrdFile}"
    '';
  };

  # TODO(jared): fix this
  boot.initrd.systemd.tpm2.enable = false;

  boot.loader.tinyboot.enable = true;

  services.yggdrasil.settings.Peers = [ "tls://celery.jmbaur.com:443" ];

  custom.desktop.enable = true;
  custom.dev.enable = true;
  nixpkgs.buildPlatform = config.nixpkgs.hostPlatform;
  custom.recovery.targetDisk = "/dev/disk/by-path/pci-0000:01:00.0-nvme-1";

  # Force using SOF driver, this is likely common to all alderlake
  # chromebook devices.
  boot.extraModprobeConfig = ''
    options snd-intel-dspcfg dsp_driver=3
  '';

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
