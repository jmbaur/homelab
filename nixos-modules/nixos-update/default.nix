{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    getExe
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.custom.update;
in
{
  options.custom.update = {
    enable = mkEnableOption "nixos-update";

    automatic = mkEnableOption "automatic updates";

    endpoint = mkOption {
      type = types.str;
      description = ''
        The HTTP endpoint to use when pulling updates.
      '';
    };
  };

  config = mkIf cfg.enable {
    # TODO(jared): We need to be able to automatically rollback from bad
    # updates, thus we need to not garbage collect known good working versions
    # in order to ensure rolling back is even possible.
    nix.gc.automatic = mkIf cfg.automatic true;

    systemd.services.nixos-update = {
      startAt = mkIf cfg.automatic [ "daily" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = toString [
          (getExe (
            pkgs.writeShellApplication {
              name = "nixos-update";
              runtimeInputs = [
                pkgs.curl
                config.nix.package
              ];
              text = builtins.readFile ./nixos-update.bash;
            }
          ))
          cfg.endpoint
        ];
      };
    };
  };
}
