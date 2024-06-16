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
      flakeRef = mkOption {
        type = types.attrs;
        description = ''
          The flake reference to build from. Currently only GitHub is
          supported.
        '';
      };
      outputAttr = mkOption {
        type = types.str;
        example = "nixosConfigurations.foo.config.system.build.toplevel";
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
      flakeRef,
      outputAttr,
      time,
      postBuild,
    }:
    let
      flakeUrl =
        assert flakeRef.type == "github";
        assert !(flakeRef ? ref);
        assert !(flakeRef ? rev);
        builtins.flakeRefToString flakeRef;
    in
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
        description = "Build ${flakeUrl}";
        path = [
          config.nix.package
          pkgs.curl
          pkgs.gitMinimal
          pkgs.jq
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
        script = # bash
          ''
            set -o errexit
            set -o nounset
            set -o pipefail
            latest_tag=$(curl --silent "https://api.github.com/repos/${flakeRef.owner}/${flakeRef.repo}/tags" | jq -r '.[0].name')
            echo "$(nix --extra-experimental-features "nix-command flakes" build --refresh --out-link "$STATE_DIRECTORY/build-${name}" --print-out-paths --print-build-logs ${flakeUrl}?ref=''${latest_tag}#${outputAttr})"
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
