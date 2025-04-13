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

  nixosUpdate = pkgs.nixos-update.override {
    nix = config.nix.package;
    systemd = config.systemd.package;
  };
in
{
  options.custom.update = {
    enable = mkEnableOption "nixos-update";

    automatic = mkEnableOption "automatic updates";

    endpoint = mkOption {
      type = types.str;
      description = ''
        The Hydra HTTP endpoint to use when pulling updates.
      '';
    };
  };

  config = mkIf cfg.enable {
    # TODO(jared): We need to be able to automatically rollback from bad
    # updates, thus we need to not garbage collect known good working versions
    # in order to ensure rolling back is even possible.
    nix.gc = mkIf cfg.automatic {
      automatic = true;
      options = "--delete-older-than 10d";
    };

    systemd.services.nixos-update = {
      stopIfChanged = false;
      restartIfChanged = false;
      reloadIfChanged = false;
      serviceConfig = {
        Type = "oneshot";
        ExecStart = toString [
          (getExe nixosUpdate)
          "update"
          "--update-endpoint=${cfg.endpoint}"
        ];
      };
    };

    systemd.timers.nixos-update = mkIf cfg.automatic {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        # Trigger the update 15min after boot, and then – on average – every
        # 6h, but randomly distributed in a 2h…6h interval. In addition trigger
        # things persistently once on each Saturday, to ensure that even on
        # systems that are never booted up for long we have a chance to do the
        # update.
        OnBootSec = "15min";
        OnUnitActiveSec = "2h";
        OnCalendar = "Sat";
        RandomizedDelaySec = "4h";
        Persistent = true;
      };
    };

    systemd.services.nixos-update-reboot = mkIf cfg.automatic {
      serviceConfig = {
        Type = "oneshot";
        ExecStart = toString [
          (getExe nixosUpdate)
          "reboot"
        ];
      };
    };

    systemd.timers.nixos-update-reboot = mkIf cfg.automatic {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "4:10";
        RandomizedDelaySec = "30min";
      };
    };
  };
}
