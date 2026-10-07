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
        "usb_storage"
        "uas"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-intel" ];
      boot.extraModulePackages = [ ];
      boot.kernelPackages = pkgs.linuxPackages_7_2;

      hardware.cpu.intel.npu.enable = true;
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    }
    {
      custom.dev.enable = true;
      custom.desktop.enable = true;
      custom.recovery.targetDisk = "/dev/disk/by-path/pci-0000:01:00.0-nvme-1";
      custom.recovery.swap = "zswap";
      custom.backup.sender.enable = false;
      services.yggdrasil.settings.Peers = [ "tls://celery.jmbaur.com:3443" ];

      services.cloudflare-warp.enable = true;
      nixpkgs.config.allowUnfree = true;

      # warp-svc can't parse systemd's "261.3" version string, so it never
      # registers its DNS proxy with resolved and falls back to writing
      # /etc/resolv.conf, which nss-resolve ignores. Its connectivity check
      # then can't resolve connectivity-check.warp-svc and it never leaves
      # "Connecting". Do the registration it would have done.
      systemd.services.cloudflare-warp-resolved = {
        description = "Route DNS through the Cloudflare WARP resolver";
        bindsTo = [ "sys-subsystem-net-devices-CloudflareWARP.device" ];
        after = [
          "sys-subsystem-net-devices-CloudflareWARP.device"
          "systemd-resolved.service"
        ];
        wantedBy = [ "sys-subsystem-net-devices-CloudflareWARP.device" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = [
            "${config.systemd.package}/bin/resolvectl dns CloudflareWARP 127.0.2.2 127.0.2.3"
            "${config.systemd.package}/bin/resolvectl domain CloudflareWARP ~."
            "${config.systemd.package}/bin/resolvectl default-route CloudflareWARP yes"
          ];
        };
      };

      hardware.saleae-logic.enable = true;
      services.udev.packages = [ pkgs.kingstvis ];
      environment.systemPackages = [
        config.hardware.saleae-logic.package
        pkgs.element-desktop
        pkgs.kingstvis
        pkgs.quartus-prime-pro-24_2
        pkgs.signal-desktop
        pkgs.slack
        pkgs.spotify
        pkgs.supersonic
        pkgs.teams-for-linux
      ];

      nix.settings = {
        extra-system-features = [ "fpga" ];
        sandbox = "relaxed";
        extra-substituters = [
          "https://cache.northwood.space"
          "https://dev-cache.northwood.space?trusted=1"
        ];
        extra-trusted-public-keys = [
          "cache.northwood.space-1:aS//R1OH2ct1xKquarzaEWRW21gDJ9pRyM8zUgvhBbc="
        ];
      };
    }
    {
      services.orbit = {
        enable = true;
        fleetUrl = "https://fleet.northwood.space";
        enrollSecretPath = "/etc/fleet/enroll-secret";
        desktop.enable = true;
      };

      # orbit launches fleet-desktop in the user's session via sudo. Upstream
      # only resolves the wrapped sudo when /etc/NIXOS exists, which is a
      # shitty heuristic.
      systemd.services.orbit.path = [ "/run/wrappers" ];
    }
    {
      environment.systemPackages = [ pkgs.agentp ];

      systemd.packages = [ pkgs.agentp ];
      systemd.services.agentpd.path = [
        "/run/wrappers" # sudo
        pkgs.coreutils-full
        pkgs.findutils
        pkgs.gawk
        pkgs.iproute2
        pkgs.lsof
      ]
      ++ lib.optionals config.networking.networkmanager.enable [ pkgs.networkmanager ];
    }
  ];
}
