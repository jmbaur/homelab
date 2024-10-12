{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkMerge [
    {
      nixpkgs.hostPlatform = "x86_64-linux";

      hardware.enableRedistributableFirmware = true;
      hardware.cpu.intel.updateMicrocode = true;
      hardware.chromebook = {
        enable = true;
        laptop = false;
      };

      boot.initrd.availableKernelModules = [
        "nvme"
        "sd_mod"
        "usb_storage"
        "xhci_pci"
      ];
      boot.initrd.kernelModules = [ "i915" ];
      boot.kernelModules = [ "kvm-intel" ];
      boot.extraModulePackages = [ ];

      tinyboot = {
        enable = true;
        board = "fizz-fizz";
      };

      hardware.graphics.extraPackages = with pkgs; [
        (intel-vaapi-driver.override { enableHybridCodec = true; })
        intel-media-driver
      ];
    }
    {
      custom.server.enable = true;
      custom.basicNetwork.enable = true;

      custom.image = {
        boot.bootLoaderSpec.enable = true;
        installer.targetDisk = "/dev/disk/by-path/pci-0000:03:00.0-nvme-1";
        mutableNixStore = true; # TODO(jared): set to false
      };

      boot.kernelParams = [ "console=ttyS0,115200" ];
      systemd.services."serial-getty@ttyS0" = {
        enable = true;
        wantedBy = [ "getty.target" ];
        serviceConfig.Restart = "always"; # restart when session is closed
      };
    }
    {
      boot.kernelParams = [ "quiet" ];

      time.timeZone = null;
      services.automatic-timezoned.enable = true;
      hardware.bluetooth.enable = true;

      hardware.graphics.enable = true;

      services.xserver.desktopManager.kodi.package =
        (pkgs.kodi-gbm.override {
          sambaSupport = false; # deps don't cross-compile
        }).withPackages
          (p: [
            p.inputstream-adaptive
            p.jellyfin
            p.joystick
          ]);

      users.users.kodi = {
        isSystemUser = true;
        home = "/var/lib/kodi";
        createHome = true;
        group = config.users.groups.kodi.name;
      };
      users.groups.kodi = { };

      systemd.services.kodi = {
        wantedBy = [ "multi-user.target" ];
        conflicts = [ "getty@tty1.service" ];
        serviceConfig = {
          User = "kodi";
          Group = "kodi";
          SupplementaryGroups = [
            "audio"
            "disk"
            "input"
            "tty"
            "video"
          ];
          TTYPath = "/dev/tty1";
          StandardInput = "tty";
          StandardOutput = "journal";
          PAMName = "login";
          ExecStart = lib.getExe' config.services.xserver.desktopManager.kodi.package "kodi-standalone";
        };
      };

      networking.firewall = {
        allowedTCPPorts = [ 8080 ];
        allowedUDPPorts = [ 8080 ];
      };

      services.pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
      };

      services.upower.enable = true;
    }
  ];
}
