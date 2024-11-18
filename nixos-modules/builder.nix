{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib)
    attrNames
    concatStringsSep
    getExe
    head
    mapAttrsToList
    mkIf
    mkMerge
    mkOption
    types
    warnIf
    ;

  cfg = config.custom.builder;

  buildModule = {
    options.build = mkOption {
      type = types.attrTag {
        drvPath = mkOption {
          type = types.str;
          description = ''
            The drv path to build. Only really useful for testing this module.
          '';
        };

        flake = mkOption {
          type = types.submodule {
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
            };
          };
        };
      };
    };

    options.time = mkOption {
      type = types.str;
      default = "daily";
      description = ''
        Any valid systemd.time(7) value.
      '';
    };

    options.postBuild = mkOption {
      type = types.nullOr types.str;
      example = "my-post-build.service";
      default = null;
      description = ''
        The systemd service to activate after a successful build. There will
        be a file at /run/build-''${name} whose contents will be the nix
        output path for the last successful build that this service should
        read from in order to condition its behavior.
      '';
    };
  };

  buildConfigs = mapAttrsToList (
    name:
    {
      build,
      time,
      postBuild,
    }:
    let
      buildType = head (attrNames build);
      build' = build.${buildType};
      flakeRefAttr = builtins.parseFlakeRef build'.flakeRef;
      buildAttr = concatStringsSep "." build'.attrPath;
    in
    assert buildType == "flake" -> flakeRefAttr.type == "github";
    warnIf (buildType == "flake" && (flakeRefAttr ? ref || flakeRefAttr ? rev))
      "ignoring ref/rev set in ${build'.flakeRef}, latest tag always built"
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
          description = "Build ${
            {
              flake = "${build'.flakeRef}#${buildAttr}";
              drvPath = build';
            }
            .${buildType}
          }";
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
                text =
                  lib.optionalString (buildType == "flake") ''
                    latest_tag=$(curl --silent "https://api.github.com/repos/${flakeRefAttr.owner}/${flakeRefAttr.repo}/tags" | jq -r '.[0].name')
                  ''
                  + ''

                    nix --extra-experimental-features "nix-command flakes" \
                      build \
                      --refresh \
                      --store "local://$STATE_DIRECTORY" \
                      --out-link "$STATE_DIRECTORY/build-${name}" \
                      --print-out-paths \
                      --print-build-logs \
                      ${
                        {
                          drvPath = "${build'}^*";
                          flake = ''${build'.flakeRef}?ref=''${latest_tag}#${buildAttr}'';
                        }
                        .${buildType}
                      }
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
            startAt = "weekly";
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
