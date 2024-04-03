{ lib, config, ... }:
let
  cfg = config.custom.server;
in
with lib;
{
  options.custom.server.enable = mkEnableOption "server";
  config = mkIf cfg.enable {
    documentation.enable = mkDefault false;
    documentation.doc.enable = mkDefault false;
    documentation.info.enable = mkDefault false;
    documentation.man.enable = mkDefault false;
    documentation.nixos.enable = mkDefault false;

    programs.command-not-found.enable = mkDefault false;

    services.udisks2.enable = mkDefault false;

    xdg.autostart.enable = mkDefault false;
    xdg.icons.enable = mkDefault false;
    xdg.mime.enable = mkDefault false;
    xdg.sounds.enable = mkDefault false;

    environment.variables.BROWSER = "echo";
    fonts.fontconfig.enable = false;

    # No need for sound on a server
    sound.enable = false;

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
  };
}
