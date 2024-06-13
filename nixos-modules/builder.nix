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
        time = lib.mkOption {
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
    { flakeUri, time }:
    {
      timers."build@${name}" = {
        timerConfig = {
          OnCalendar = time;
          Persistent = true;
        };
        wantedBy = [ "timers.target" ];
      };

      services."build@${name}" = {
        description = "Build ${flakeUri}";
        requiredBy = [ config.systemd.services.post-build.name ];
        path = [
          config.nix.package
          pkgs.git
          pkgs.mercurial
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
          out_link=$STATE_DIRECTORY/result-${name}

          nix --extra-experimental-features "nix-command flakes" \
            build --refresh --print-out-paths --print-build-logs \
            --out-link "$out_link" \
            ${flakeUri}

          echo "${name} $out_link" >/run/post-build.stdin
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

    # TODO(jared): this abstraction isn't nice...
    postBuild = mkOption {
      type = types.unspecified;
      default = { };
      description = ''
        Systemd service definition that will be notified after each build. The
        program ran within the service will receive on its stdin a single line
        for each build of the format "<build-name> <output-path>".
      '';
    };
  };

  config = lib.mkIf (cfg.builds != { }) {
    users.groups.builder = { };
    nix.settings.trusted-users = [ "@builder" ];

    custom.builder.postBuild = {
      description = "Post Build Hook";
      serviceConfig = {
        StandardInput = "file:/run/post-build.stdin";
        # # Ensure the post-build service can read the fifo
        # SupplementaryGroups = [ config.users.groups.builder.name ];
      };
    };

    systemd = lib.mkMerge (
      buildConfigs
      ++ [
        {
          tmpfiles.settings."10-post-build"."/run/post-build.stdin"."p+" = {
            mode = "0460";
            user = "root";
            group = config.users.groups.builder.name;
          };
          services.post-build = cfg.postBuild;
        }
      ]
    );
  };
}
