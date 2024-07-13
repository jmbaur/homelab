{
  config,
  lib,
  pkgs,
  ...
}:

let
  allFirmwareName = "all_firmware.tar.gz";
  allFirmware = pkgs.fetchurl {
    url = "https://pub-ad3dbf7e26e24a8797839df34ab02dac.r2.dev/${allFirmwareName}";
    hash = "sha256-MgQGQLP3ybFW8yhbhmkaE6d/BkAR6+0bFRe+4LJYoes=";
  };

  kernelcacheName = "kernelcache.release.mac13g";
  kernelcache = pkgs.fetchurl {
    url = "https://pub-ad3dbf7e26e24a8797839df34ab02dac.r2.dev/${kernelcacheName}";
    hash = "sha256-sD3quAMvZTYQxbk7gdtt2NAkj50gvrfHSR7rT0ptsVE=";
  };

  asahiFirmware = pkgs.callPackage (
    {
      runCommand,
      asahi-fwextract,
      cpio,
    }:
    runCommand "asahi-firmware"
      {
        nativeBuildInputs = [
          asahi-fwextract
          cpio
        ];
      }
      ''
        extracted=$(mktemp -d)
        cp ${allFirmware} ${allFirmwareName}
        cp ${kernelcache} ${kernelcacheName}
        asahi-fwextract . $extracted
        cat $extracted/firmware.cpio | cpio -id --quiet --no-absolute-filenames
        mkdir -p $out/lib/firmware
      ''
  ) { };

  bootBin = pkgs.runCommand "boot.bin" { } ''
    cat ${pkgs.m1n1}/build/m1n1.bin > $out
    cat ${config.boot.kernelPackages.kernel}/dtbs/apple/*.dtb >> $out
    cat ${pkgs.uboot-asahi}/u-boot-nodtb.bin.gz >> $out
  '';
in

{
  config = lib.mkMerge [
    {
      nixpkgs.hostPlatform = "aarch64-linux";

      # The devicetree lives in m1n1 image
      hardware.deviceTree.enable = false;

      # For ` to < and ~ to > (for those with US keyboards)
      boot.extraModprobeConfig = ''
        options hid_apple iso_layout=0
      '';

      custom.normalUser.enable = true;
      custom.dev.enable = true;
      custom.image = {
        sectorSize = 4096;
        installer.targetDisk = "/dev/disk/by-path/platform-27bcc0000.nvme-nvme-1";
        boot.uefi.enable = true;
        bootFileCommands = ''
          echo ${bootBin}:/m1n1/boot.bin >> $bootfiles
        '';
      };

      # These partitions already exist from the macOS installation, we just
      # declare them in the systemd-repart config to be complete.
      #
      # $ sudo fdisk -l -o+UUID /dev/nvme0n1
      # Disk /dev/nvme0n1: 233.76 GiB, 251000193024 bytes, 61279344 sectors
      # Disk model: APPLE SSD AP0256Q
      # Units: sectors of 1 * 4096 = 4096 bytes
      # Sector size (logical/physical): 4096 bytes / 4096 bytes
      # I/O size (minimum/optimal): 4096 bytes / 4096 bytes
      # Disklabel type: gpt
      # Disk identifier: ...
      #
      # Device            Start      End  Sectors   Size Type                   UUID
      # /dev/nvme0n1p1        6   128005   128000   500M Apple Silicon boot     B073AD4B-EB7D-4653-8B7C-F972ACD238D6
      # /dev/nvme0n1p2   128006 30048517 29920512 114.1G Apple APFS             8FF532A2-34DB-4B6C-AD33-BDC5D58C98B5
      # /dev/nvme0n1p3 30048518 30658821   610304   2.3G Apple APFS             D4F06C86-F965-473E-B536-E88AB8F9365F
      # ...
      # /dev/nvme0n1p6 59968630 61279338  1310709     5G Apple Silicon recovery 115B8828-2BE0-4818-9659-1223B367E77F
      systemd.repart.partitions = {
        "01-apple-silicon-boot" = {
          Type = "69646961-6700-11AA-AA11-00306543ECAC";
          Label = "iBootSystemContainer";
          SizeMinBytes = "500M";
          SizeMaxBytes = "500M";
        };
        "02-apfs-1" = {
          Type = "7C3457EF-0000-11AA-AA11-00306543ECAC";
          Label = "Container";
          SizeMinBytes = "50G";
          SizeMaxBytes = "50G";
        };
        "02-apfs-2" = {
          Type = "7C3457EF-0000-11AA-AA11-00306543ECAC";
          Label = "";
          SizeMinBytes = "2GM";
          SizeMaxBytes = "2GM";
        };
        "99-apple-silicon-recovery" = {
          Type = "52637672-7900-11AA-AA11-00306543ECAC";
          Label = "RecoveryOSContainer";
          SizeMinBytes = "5G";
          SizeMaxBytes = "5G";
        };
      };
    }

    # Mostly copied from tpwrules/nixos-apple-silicon
    {
      boot.kernelPackages = pkgs.linux-asahi.override {
        _kernelPatches = config.boot.kernelPatches;
        withRust = true;
      };

      # we definitely want to use CONFIG_ENERGY_MODEL, and
      # schedutil is a prerequisite for using it
      # source: https://www.kernel.org/doc/html/latest/scheduler/sched-energy.html
      powerManagement.cpuFreqGovernor = lib.mkOverride 800 "schedutil";

      boot.initrd.includeDefaultModules = false;
      boot.initrd.availableKernelModules = [
        # list of initrd modules stolen from
        # https://github.com/AsahiLinux/asahi-scripts/blob/f461f080a1d2575ae4b82879b5624360db3cff8c/initcpio/install/asahi
        "apple-mailbox"
        "nvme_apple"
        "pinctrl-apple-gpio"
        "macsmc"
        "macsmc-rtkit"
        "i2c-pasemi-platform"
        "tps6598x"
        "apple-dart"
        "dwc3"
        "dwc3-of-simple"
        "xhci-pci"
        "pcie-apple"
        "gpio_macsmc"
        "phy-apple-atc"
        "nvmem_apple_efuses"
        "spi-apple"
        "spi-hid-apple"
        "spi-hid-apple-of"
        "rtc-macsmc"
        "simple-mfd-spmi"
        "spmi-apple-controller"
        "nvmem_spmi_mfd"
        "apple-dockchannel"
        "dockchannel-hid"
        "apple-rtkit-helper"

        # additional stuff necessary to boot off USB for the installer
        # and if the initrd (i.e. stage 1) goes wrong
        "usb-storage"
        "xhci-plat-hcd"
        "usbhid"
        "hid_generic"
      ];

      boot.kernelParams = [
        "earlycon"
        "console=ttySAC0,115200n8"
        "console=tty0"
        "boot.shell_on_fail"
        # Apple's SSDs are slow (~dozens of ms) at processing flush requests which
        # slows down programs that make a lot of fsync calls. This parameter sets
        # a delay in ms before actually flushing so that such requests can be
        # coalesced. Be warned that increasing this parameter above zero (default
        # is 1000) has the potential, though admittedly unlikely, risk of
        # UNBOUNDED data corruption in case of power loss!!!! Don't even think
        # about it on desktops!!
        "nvme_apple.flush_interval=0"
      ];

      # U-Boot does not support EFI variables
      boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

      # U-Boot does not support switching console mode
      boot.loader.systemd-boot.consoleMode = "0";

      # GRUB has to be installed as removable if the user chooses to use it
      boot.loader.grub = lib.mkDefault {
        efiSupport = true;
        efiInstallAsRemovable = true;
        device = "nodev";
      };

      # autosuspend was enabled as safe for the PCI SD card reader
      # "Genesys Logic, Inc GL9755 SD Host Controller [17a0:9755] (rev 01)"
      # by recent systemd versions, but this has a "negative interaction"
      # with our kernel/SoC and causes random boot hangs. disable it!
      services.udev.extraHwdb = ''
        pci:v000017A0d00009755*
          ID_AUTOSUSPEND=0
      '';

      # required for proper DRM setup even without GPU driver
      services.xserver.config = ''
        Section "OutputClass"
            Identifier "appledrm"
            MatchDriver "apple"
            Driver "modesetting"
            Option "PrimaryGPU" "true"
        EndSection
      '';

      hardware.graphics.package = pkgs.mesa-asahi-edge.drivers;

      nixpkgs.overlays = lib.mkAfter [ (final: _: { mesa = final.mesa-asahi-edge; }) ];

      hardware.firmware = [ asahiFirmware ];
    }

    (lib.mkIf config.sound.enable {
      # enable pipewire to run real-time and avoid audible glitches
      security.rtkit.enable = true;
      # set up pipewire with the supported capabilities (instead of pulseaudio)
      # and asahi-audio configs and plugins
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;

        configPackages = [ pkgs.asahi-audio ];
        extraLv2Packages = [
          pkgs.lsp-plugins
          pkgs.bankstown-lv2
        ];

        wireplumber = {
          enable = true;

          configPackages = [ pkgs.asahi-audio ];
          extraLv2Packages = [
            pkgs.lsp-plugins
            pkgs.bankstown-lv2
          ];
        };
      };

      # set up enivronment so that UCM configs are used as well
      environment.variables.ALSA_CONFIG_UCM2 = "${pkgs.alsa-ucm-conf-asahi}/share/alsa/ucm2";
      systemd.user.services.pipewire.environment.ALSA_CONFIG_UCM2 =
        config.environment.variables.ALSA_CONFIG_UCM2;
      systemd.user.services.wireplumber.environment.ALSA_CONFIG_UCM2 =
        config.environment.variables.ALSA_CONFIG_UCM2;

      # enable speakersafetyd to protect speakers
      systemd.packages =
        let
          lsp-plugins-is-safe = (pkgs.lib.versionAtLeast pkgs.lsp-plugins.version "1.2.14");
        in
        lib.mkAssert lsp-plugins-is-safe
          "lsp-plugins is unpatched/outdated and speakers cannot be safely enabled"
          [ pkgs.speakersafetyd ];
      services.udev.packages = [ pkgs.speakersafetyd ];

      # asahi-sound requires wireplumber 0.5.2 or above
      # https://github.com/AsahiLinux/asahi-audio/commit/29ec1056c18193ffa09a990b1b61ed273e97fee6
      assertions = [
        {
          assertion = lib.versionAtLeast pkgs.wireplumber.version "0.5.2";
          message = "wireplumber >= 0.5.2 is required for sound with nixos-apple-silicon.";
        }
      ];
    })
  ];
}
