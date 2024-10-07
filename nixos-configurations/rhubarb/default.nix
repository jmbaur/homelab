{
  config,
  lib,
  pkgs,
  ...
}:

let
  kernelLoadAddress = 524288;
  bootmLen = 80 * 1024 * 1024; # 80MiB

  uboot = pkgs.uboot-rpi_4.override {
    extraStructuredConfig = with lib.kernel; {
      DISTRO_DEFAULTS = unset;
      BOOTSTD_DEFAULTS = yes;
      FIT = yes;

      # Allow for larger than the default 8MiB kernel size
      SYS_BOOTM_LEN = freeform "0x${lib.toHexString bootmLen}";
      SYS_LOAD_ADDR = freeform "0x${lib.toHexString (bootmLen + kernelLoadAddress)}";

      # Allow for using u-boot scripts.
      BOOTSTD_FULL = yes;

      BOOTCOUNT_LIMIT = yes;
      BOOTCOUNT_ENV = yes;
    };
  };

  configTxt = pkgs.writeText "config.txt" ''
    [all]
    arm_64bit=1
    arm_boost=1
    armstub=armstub8-gic.bin
    avoid_warnings=1
    disable_overscan=1
    enable_gic=1
    enable_uart=1
    kernel=kernel8.img
  '';
in
{
  config = lib.mkMerge [
    {
      nixpkgs.hostPlatform = "aarch64-linux";

      system.build.rpiSupportFiles = pkgs.runCommand "rpi-support-files" { } ''
        echo ${config.system.build.firmware}/u-boot.bin:/kernel8.img >> $out
        echo ${configTxt}:/config.txt >> $out
        echo ${pkgs.raspberrypi-armstubs}/armstub8-gic.bin:/armstub8-gic.bin >> $out
        echo ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2711-rpi-4-b.dtb:/bcm2711-rpi-4-b.dtb >> $out
        find ${pkgs.raspberrypifw}/share/raspberrypi/boot -name "fixup*" \
          -exec sh -c 'echo {}:/$(basename {})' \; >> $out
        find ${pkgs.raspberrypifw}/share/raspberrypi/boot -name "start*" \
          -exec sh -c 'echo {}:/$(basename {})' \; >> $out
      '';

      custom.image = {
        bootFileCommands = ''
          cat ${config.system.build.rpiSupportFiles} >> $bootfiles
        '';
        postImageCommands = ''
          # Modify the protective MBR to expose the EFI system partition on the MBR table
          ${lib.getExe' pkgs.buildPackages.gptfdisk "sgdisk"} --hybrid=1:EE $out/image.raw
          # Change the partition type of the EFI system partition on the MBR table to type 0xb (https://en.wikipedia.org/wiki/Partition_type#PID_0Bh).
          printf '\x0b' | dd status=none of=$out/image.raw bs=1 seek=$((0x1c2)) count=1 conv=notrunc
        '';
      };

      # https://forums.raspberrypi.com/viewtopic.php?t=319435
      # systemd.repart.partitions."10-boot".Type = lib.mkForce "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7";

      system.build.firmware = uboot;

      hardware.deviceTree.enable = true;
      hardware.deviceTree.name = "broadcom/bcm2711-rpi-4-b.dtb";

      boot.kernelParams = [ "console=ttyS1,115200" ];

      environment.etc."fw_env.config".text = ''
        ${config.boot.loader.efi.efiSysMountPoint}/uboot.env 0x0000 0x10000
      '';

      environment.systemPackages = [ pkgs.uboot-env-tools ];
    }
    {
      custom.server.enable = true;
      custom.basicNetwork.enable = true;
      custom.nativeBuild = true;
      custom.image = {
        installer.targetDisk = "/dev/mmcblk0";
        boot.uboot = {
          enable = true;
          bootMedium.type = "mmc";
          kernelLoadAddress = "0x${lib.toHexString kernelLoadAddress}";
        };
      };
    }
    {
      # Undo the settings we set in <homelab/nixos-modules/server.nix>, they
      # doesn't work on the RPI4. TODO(jared): figure out how to get rid of
      # this.
      systemd.watchdog = {
        runtimeTime = null;
        rebootTime = null;
      };
    }
    {
      time.timeZone = null;
      services.automatic-timezoned.enable = true;
      hardware.bluetooth.enable = true;

      services.xserver.desktopManager.kodi.package = pkgs.kodi.override {
        gbmSupport = true;
        pipewireSupport = true;
        sambaSupport = false; # deps don't cross-compile
        waylandSupport = true;
        x11Support = false;
      };

      users.users.kodi = {
        isSystemUser = true;
        home = "/var/lib/kodi";
        createHome = true;
        group = config.users.groups.kodi.name;
        extraGroups = [
          "audio"
          "disk"
          "input"
          "tty"
          "video"
        ];
      };
      users.groups.kodi = { };

      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (subject.user == "kodi") {
            polkit.log("action=" + action);
            polkit.log("subject=" + subject);
            if (action.id.indexOf("org.freedesktop.login1.") == 0) {
              return polkit.Result.YES;
            }
            if (action.id.indexOf("org.freedesktop.udisks.") == 0) {
              return polkit.Result.YES;
            }
            if (action.id.indexOf("org.freedesktop.udisks2.") == 0) {
              return polkit.Result.YES;
            }
          }
        });
      '';

      services.udev.extraRules = ''
        SUBSYSTEM=="vc-sm",GROUP="video",MODE="0660"
        KERNEL=="vchiq",GROUP="video",MODE="0660"
        SUBSYSTEM=="tty",KERNEL=="tty[0-9]*",GROUP="tty",MODE="0660"
        SUBSYSTEM=="dma_heap",KERNEL=="linux*",GROUP="video",MODE="0660"
        SUBSYSTEM=="dma_heap",KERNEL=="system",GROUP="video",MODE="0660"
      '';

      # systemd.defaultUnit = "graphical.target";
      # systemd.services.kodi = {
      #   description = "Description=Kodi standalone (GBM)";
      #   aliases = [ "display-manager.service" ];
      #   conflicts = [ "getty@tty1.service" ];
      #   wants = [
      #     "polkit.service"
      #     "upower.service"
      #   ];
      #   after = [
      #     "remote-fs.target"
      #     "systemd-user-sessions.service"
      #     "nss-lookup.target"
      #     "sound.target"
      #     "bluetooth.target"
      #     "polkit.service"
      #     "upower.service"
      #     "mysqld.service"
      #     "lircd.service"
      #   ];
      #   serviceConfig = {
      #     User = "kodi";
      #     Group = "kodi";
      #     PAMName = "login";
      #     Restart = "on-abort";
      #     StandardInput = "tty";
      #     StandardOutput = "journal";
      #     TTYPath = "/dev/tty1";
      #     ExecStart = "${lib.getExe config.services.xserver.desktopManager.kodi.package} --standalone --windowing=gbm";
      #   };
      # };

      networking.firewall = {
        allowedTCPPorts = [ 8080 ];
        allowedUDPPorts = [ 8080 ];
      };

      services.cage = {
        enable = true;
        user = config.users.users.kodi.name;
        program = lib.getExe' config.services.xserver.desktopManager.kodi.package "kodi-standalone";
      };
    }
  ];
}
