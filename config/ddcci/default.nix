{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.custom.ddcci;
in
{
  options = {
    custom.ddcci = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable ddcci on the system to allow for changing of non-builtin
          monitor brightness and other settings. If a user is in the `users`
          group, they will have permission to use ddcutil.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    boot.kernelModules = [ "i2c-dev" ];
    services.udev.extraRules = ''KERNEL=="i2c-[0-9]*", GROUP+="users"'';
    environment.systemPackages = [ pkgs.ddcutil ];
  };

}
