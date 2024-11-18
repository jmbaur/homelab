{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib)
    concatStringsSep
    getExe
    mapAttrsToList
    mkIf
    mkMerge
    mkOption
    types
    warnIf
    ;

  cfg = config.custom.builder;

  buildModule = {
    options = {
      flakeRef = mkOption {
        type = types.str;
        example = "github:nixos/nixpkgs";
        description = ''
          The flake reference to build from.

          Currently only GitHub is supported.
        '';
      };
      attrPath = mkOption {
        type = types.listOf types.str;
        example = [
          "legacyPackages"
          "x86_64-linux"
          "hello"
        ];
      };
      time = mkOption {
        type = types.str;
        default = "daily";
        description = ''
          Any valid systemd.time(7) value.
        '';
      };
      postBuild = mkOption {
        type = types.nullOr types.str;
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

  buildConfigs = mapAttrsToList (
    name:
    {
      flakeRef,
      attrPath,
      time,
      postBuild,
    }:
    let
      flakeRefAttr = builtins.parseFlakeRef flakeRef;
      buildAttr = concatStringsSep "." attrPath;
    in
    assert flakeRefAttr.type == "github";
    warnIf (flakeRefAttr ? ref || flakeRefAttr ? rev)
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
          onSuccess = lib.optionals (postBuild != null) [ postBuild ];
          description = "Build ${flakeRef}#${buildAttr}";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          environment = {
            XDG_CACHE_HOME = "%C/builder";
            XDG_STATE_HOME = "%S/builder";
          };
          serviceConfig = {
            StandardOutput = "truncate:/run/build-${name}";
            StandardError = "journal";
            DynamicUser = true;
            SupplementaryGroups = [ "builder" ];
            CacheDirectory = "builder";
            StateDirectory = "builder";
            ExecStart = getExe (
              pkgs.writeShellApplication {
                name = "build-${name}";
                runtimeInputs = [
                  config.nix.package
                  pkgs.curl
                  pkgs.gitMinimal
                  pkgs.jq
                ];
                text = ''
                  latest_tag=$(curl --silent "https://api.github.com/repos/${flakeRefAttr.owner}/${flakeRefAttr.repo}/tags" | jq -r '.[0].name')

                  nix --extra-experimental-features "nix-command flakes" \
                    build \
                    --refresh \
                    --store "local://$STATE_DIRECTORY" \
                    --out-link "$STATE_DIRECTORY/build-${name}" \
                    --print-out-paths \
                    --print-build-logs \
                    "${flakeRef}?ref=''${latest_tag}#${buildAttr}"
                '';
              }
            );
          };
        };
      }
  ) cfg.builds;

in
{
  options.custom.builder = {
    builds = mkOption {
      type = types.attrsOf (types.submodule buildModule);
      default = { };
    };
  };

  config = mkIf (cfg.builds != { }) {
    users.groups.builder = { };
    nix.settings.trusted-users = [ "@builder" ];

    systemd = mkMerge (
      buildConfigs
      ++ [
        {
          # Mostly copied from https://github.com/nixos/nixpkgs/blob/6a70100fb702712aa13f630c833e2c33c6e21ee2/nixos/modules/services/misc/nix-gc.nix,
          # since that module doesn't work when nix itself is not enabled.
          services.builder-nix-gc = lib.mkIf config.nix.enable {
            description = "Nix Garbage Collector";
            startAt = lib.optional cfg.automatic cfg.dates;
            script = ''exec ${lib.getExe' config.nix.package "nix-collect-garbage"} --store "local://$STATE_DIRECTORY"'';
            environment = {
              XDG_CACHE_HOME = "%C/builder";
              XDG_STATE_HOME = "%S/builder";
            };
            serviceConfig = {
              Type = "oneshot";
              DynamicUser = true;
              SupplementaryGroups = [ "builder" ];
              CacheDirectory = "builder";
              StateDirectory = "builder";
            };
          };

          timers.builder-nix-gc.timerConfig.Persistent = true;
        }
      ]
    );
  };
}
