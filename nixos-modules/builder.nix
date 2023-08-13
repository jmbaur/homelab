{ config, pkgs, lib, ... }:
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
        path = [ config.nix.package pkgs.git ];
        environment = {
          XDG_CACHE_HOME = "%C/builder";
          XDG_STATE_HOME = "%S/builder";
        };
        serviceConfig = {
          DynamicUser = true;
          User = "builder";
          CacheDirectory = "builder";
          StateDirectory = "builder";
        };
        script = ''
          nix \
            --accept-flake-config \
            --extra-experimental-features "nix-command flakes" \
            build --refresh --print-out-paths --print-build-logs \
            --out-link $STATE_DIRECTORY/result-${name} \
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
    users.groups.builder = { };
    nix.settings.trusted-users = [ "builder" ];
    systemd.timers = lib.mapAttrs (_: { timer, ... }: timer) systemdConfigs;
    systemd.services = lib.mapAttrs (_: { service, ... }: service) systemdConfigs;
  };
}
