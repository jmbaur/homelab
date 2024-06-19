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
        type = types.str;
        example = "github:nixos/nixpkgs";
        description = ''
          The flake reference to build from.

          Currently only GitHub is supported.
        '';
      };
      outputAttr = mkOption {
        type = types.str;
        example = "legacyPackages.x86_64-linux.hello";
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
        example = "my-post-build.service";
        description = ''
          The systemd service to activate after a successful build. There will
          be a file at /run/build-''${name} whose contents will be the nix
          output path for the last successful build that this service should
          read from in order to condition its behavior.
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
      flakeRefAttr = builtins.parseFlakeRef flakeRef;
    in
    assert flakeRefAttr.type == "github";
    lib.warnIf (flakeRefAttr ? ref || flakeRefAttr ? rev)
      "ignoring ref/rev set in ${flakeRef}, latest tag always built"
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
          description = "Build ${flakeRef}";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          path = [
            config.nix.package
            pkgs.curl
            pkgs.gitMinimal
            pkgs.jq
          ];
          environment = {
            NIX_REMOTE = "daemon";
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

              latest_tag=$(curl --silent "https://api.github.com/repos/${flakeRefAttr.owner}/${flakeRefAttr.repo}/tags" | jq -r '.[0].name')

              nix --extra-experimental-features "nix-command flakes" \
                build \
                --refresh \
                --out-link "$STATE_DIRECTORY/build-${name}" \
                --print-out-paths \
                --print-build-logs \
                "${flakeRef}?ref=''${latest_tag}#${outputAttr}"
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
