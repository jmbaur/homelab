{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.builder;

  buildModule =
    { ... }:
    {
      options = {
        flakeUri = lib.mkOption { type = lib.types.str; };
        frequency = lib.mkOption {
          type = lib.types.str;
          default = "daily";
          description = ''
            Any valid systemd.time(7) value.
          '';
        };
      };
    };

  buildConfigs = lib.mapAttrsToList (
    name:
    { flakeUri, frequency }:
    {
      timers."build@${name}" = {
        timerConfig = {
          OnCalendar = frequency;
          Persistent = true;
        };
        wantedBy = [ "timers.target" ];
      };

      services."build@${name}" = {
        description = "Build ${flakeUri}";
        path = [
          config.nix.package
          pkgs.git
        ];
        environment = {
          XDG_CACHE_HOME = "%C/builder";
          XDG_STATE_HOME = "%S/builder";
        };
        serviceConfig = {
          DynamicUser = true;
          SupplementaryGroups = [ "builder" ];
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
    }
  ) cfg.builds;

in
{
  options.custom.builder.builds = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule buildModule);
    default = { };
  };

  config = lib.mkIf (cfg.builds != { }) {
    users.groups.builder = { };
    nix.settings.trusted-users = [ "@builder" ];
    systemd = lib.mkMerge buildConfigs;
  };
}
