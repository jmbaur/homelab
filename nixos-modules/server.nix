{
  lib,
  config,
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

    environment.variables.BROWSER = "echo";
    fonts.fontconfig.enable = false;

    # UTC everywhere!
    time.timeZone = lib.mkDefault "UTC";

    systemd = {
      # Given that our systems are headless, emergency mode is useless.
      # We prefer the system to attempt to continue booting so
      # that we can hopefully still access it remotely.
      enableEmergencyMode = false;

      # For more detail, see:
      #   https://0pointer.de/blog/projects/watchdog.html
      watchdog = {
        # systemd will send a signal to the hardware watchdog at half
        # the interval defined here, so every 10s.
        # If the hardware watchdog does not get a signal for 20s,
        # it will forcefully reboot the system.
        runtimeTime = "20s";
        # Forcefully reboot if the final stage of the reboot
        # hangs without progress for more than 30s.
        # For more info, see:
        #   https://utcc.utoronto.ca/~cks/space/blog/linux/SystemdShutdownWatchdog
        rebootTime = "30s";
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

    users.users.root.openssh.authorizedKeys.keyFiles = [ pkgs.jmbaur-ssh-keys ];

    services.prometheus.exporters.node = {
      enable = true;
      enabledCollectors = [
        "logind"
        "systemd"
      ];
    };
  };
}
