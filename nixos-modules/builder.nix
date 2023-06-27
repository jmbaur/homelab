{ config, lib, ... }:
let
  cfg = config.custom.builder;

  buildModule = { ... }: {
    options = {
      flakeUri = lib.mkOption {
        type = lib.types.str;
      };
      frequency = lib.mkOption {
        type = lib.types.str;
        default = "daily";
        description = lib.mdDoc ''
          Any value systemd.time(7) value.
        '';
      };
    };
  };

  systemdConfigs = lib.mapAttrs'
    (name: { flakeUri, frequency }: lib.nameValuePair "build@${name}" {
      timer = {
        timerConfig = {
          OnCalendar = frequency;
          Persistent = true;
        };
        wantedBy = [ "timers.target" ];
      };

      service = {
        description = "Build ${flakeUri}";
        path = [ config.nix.package ];
        script = ''
          nix \
            --extra-experimental-features "nix-command flakes" \
            build --refresh --no-link --print-out-paths --print-build-logs \
            ${flakeUri}
        '';
      };
    })
    cfg.build;

in
{
  options.custom.builder = {
    build = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule buildModule);
      default = { };
    };
  };

  config = lib.mkIf (cfg.build != { }) {
    systemd.timers = lib.mapAttrs (_: { timer, ... }: timer) systemdConfigs;
    systemd.services = lib.mapAttrs (_: { service, ... }: service) systemdConfigs;
  };
}
