{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mapAttrs'
    mkEnableOption
    mkOption
    nameValuePair
    types
    ;

  cfg = config.custom.server;

  network = import ./network.nix { inherit lib; };

  interfaceSubmodule =
    { name, ... }:
    {
      options = {
        name = mkOption {
          readOnly = true;
          default = name;
          description = ''
            TODO
          '';
        };
        matchConfig = mkOption {
          type = types.attrs;
          description = ''
            TODO
          '';
        };
      };
    };
in
{
  options.custom.server = {
    enable = mkEnableOption "server";

    interfaces = mkOption {
      type = types.attrsOf (types.submodule interfaceSubmodule);
      default = { };
      description = ''
        TODO
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    documentation.enable = lib.mkDefault false;
    documentation.doc.enable = lib.mkDefault false;
    documentation.info.enable = lib.mkDefault false;
    documentation.man.enable = lib.mkDefault false;
    documentation.nixos.enable = lib.mkDefault false;

    systemd.network = {
      enable = true;
      networks = mapAttrs' (
        name: interface:
        nameValuePair "10-${name}" {
          inherit (interface) matchConfig;
          networkConfig = {
            DHCP = "ipv4";
            Domains = "~.";
          };
          ipv6AcceptRAConfig = {
            Token = "static:${network.${name}}";
            UseDomains = "route";
          };
        }
      ) cfg.interfaces;
    };

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

      settings.Manager = {
        KExecWatchdogSec = lib.mkDefault "30s";
        RebootWatchdogSec = lib.mkDefault "30s";
        RuntimeWatchdogSec = lib.mkDefault "20s";
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
