{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.custom.server.enable = lib.mkEnableOption "server";

  config = lib.mkIf config.custom.server.enable {
    documentation.enable = lib.mkDefault false;
    documentation.doc.enable = lib.mkDefault false;
    documentation.info.enable = lib.mkDefault false;
    documentation.man.enable = lib.mkDefault false;
    documentation.nixos.enable = lib.mkDefault false;

    programs.command-not-found.enable = lib.mkDefault false;

    services.udisks2.enable = lib.mkDefault false;

    xdg.autostart.enable = lib.mkDefault false;
    xdg.icons.enable = lib.mkDefault false;
    xdg.mime.enable = lib.mkDefault false;
    xdg.sounds.enable = lib.mkDefault false;

    environment.variables.BROWSER = lib.getExe (
      pkgs.w3m.override {
        x11Support = false;
        graphicsSupport = false;
      }
    );

    fonts.fontconfig.enable = lib.mkDefault false;

    # UTC everywhere!
    time.timeZone = lib.mkDefault "UTC";

    systemd = {
      # Given that our systems are headless, emergency mode is useless.
      # We prefer the system to attempt to continue booting so
      # that we can hopefully still access it remotely.
      enableEmergencyMode = false;

      watchdog = {
        runtimeTime = lib.mkDefault "20s";
        rebootTime = lib.mkDefault "30s";
        kexecTime = lib.mkDefault "30s";
      };

      sleep.extraConfig = ''
        AllowSuspend=no
        AllowHibernation=no
      '';
    };

    # use TCP BBR has significantly increased throughput and reduced latency for connections
    boot.kernel.sysctl = {
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
    };

    # Since we can't manually respond to a panic, just reboot.
    boot.kernelParams = [
      "panic=1"
      "boot.panic_on_fail"
    ];

    services.prometheus.exporters.node = {
      enable = true;
      enabledCollectors = [
        "logind"
        "systemd"
      ];
    };
  };
}
