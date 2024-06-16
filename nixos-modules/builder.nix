{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.builder;

  buildModule = {
    options = with lib; {
      flakeUri = mkOption {
        type = types.str;
        description = ''
          The flake URI to build. Currently, this must come from a public
          source.
        '';
      };
      time = mkOption {
        type = types.str;
        default = "daily";
        description = ''
          Any valid systemd.time(7) value.
        '';
      };
      postBuild = mkOption {
        type = types.str;
        description = ''
          The systemd service to activate after a successful build. There will
          be a file at /run/build-''${name} whose contents will be the nix
          output path for the last successful build that this service should
          read from to condition its behavior.
        '';
      };
    };
  };

  buildConfigs = lib.mapAttrsToList (
    name:
    {
      flakeUri,
      time,
      postBuild,
    }:
    {
      timers."build@${name}" = {
        timerConfig = {
          OnCalendar = time;
          Persistent = true;
        };
        wantedBy = [ "timers.target" ];
      };

      services."build@${name}" = {
        onSuccess = [ postBuild ];
        description = "Build ${flakeUri}";
        path = [
          config.nix.package
          pkgs.gitMinimal
        ];
        environment = {
          XDG_CACHE_HOME = "%C/builder";
          XDG_STATE_HOME = "%S/builder";
        };
        serviceConfig = {
          DynamicUser = true;
          StandardOutput = "truncate:/run/build-${name}";
          StandardError = "journal";
          SupplementaryGroups = [ "builder" ];
          CacheDirectory = "builder";
          StateDirectory = "builder";
        };
        script = ''
          set -o errexit
          set -o nounset
          set -o pipefail
          echo "$(nix --extra-experimental-features "nix-command flakes" build --refresh --no-link --print-out-paths --print-build-logs ${flakeUri})"
        '';
      };
    }
  ) cfg.builds;

in
{
  options.custom.builder = with lib; {
    builds = mkOption {
      type = types.attrsOf (types.submodule buildModule);
      default = { };
    };
  };

  config = lib.mkIf (cfg.builds != { }) {
    users.groups.builder = { };
    nix.settings.trusted-users = [ "@builder" ];

    systemd = lib.mkMerge buildConfigs;
  };
}
