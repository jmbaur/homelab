{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    "${modulesPath}/hardware/cpu/intel-npu.nix"
    "${modulesPath}/installer/scan/not-detected.nix"
  ];

  config = lib.mkMerge [
    {
      nixpkgs.hostPlatform = "x86_64-linux";

      boot.initrd.availableKernelModules = [
        "xhci_pci"
        "thunderbolt"
        "nvme"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-intel" ];
      boot.extraModulePackages = [ ];

      hardware.cpu.intel.npu.enable = true;
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    }
    {
      custom.dev.enable = true;
      custom.desktop.enable = true;
      custom.recovery.targetDisk = "/dev/disk/by-path/pci-0000:01:00.0-nvme-1";
      custom.backup.sender.enable = false;
      services.yggdrasil.enable = false;

      services.cloudflare-warp.enable = true;
      nixpkgs.config.allowUnfree = true;

      virtualisation.podman.enable = true;

      hardware.saleae-logic.enable = true;
      environment.systemPackages = [ config.hardware.saleae-logic.package ];

      nix.settings = {
        extra-substituters = [ "https://cache.northwood.space" ];
        extra-trusted-public-keys = [
          "cache.northwood.space-1:aS//R1OH2ct1xKquarzaEWRW21gDJ9pRyM8zUgvhBbc="
        ];
      };
    }
    {
      environment.systemPackages = [ pkgs.fleetctl ];

      systemd.services.orbit = {
        description = "Orbit osquery";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        unitConfig.StartLimitIntervalSec = 0;
        serviceConfig = {
          EnvironmentFile = "/etc/orbit.env";
          Restart = "always";
          RestartSec = 1;
          KillMode = "control-group";
          KillSignal = "SIGTERM";
          CPUQuota = "20%";
          StateDirectory = "orbit";
          BindPaths = [ "%S/orbit:/opt" ];
          BindReadOnlyPaths = [
            "${lib.getExe' pkgs.fleet "desktop"}:/opt/orbit/bin/desktop/linux/stable/fleet-desktop/fleet-desktop"
            "${lib.getExe' pkgs.osquery "osqueryd"}:/opt/orbit/bin/osqueryd/linux/stable/osqueryd"
            "${pkgs.osquery}:/opt/osquery"
          ];
          ExecStart = toString [
            (lib.getExe' pkgs.fleet "orbit")
            "--disable-updates"
          ];
        };
      };
    }
  ];
}
