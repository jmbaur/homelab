{ lib, config, pkgs, ... }:
let
  cfg = config.custom.users.jared;
in
{
  options.custom.users.jared = with lib; {
    enable = mkEnableOption "jared";
    username = mkOption {
      type = types.str;
      default = "jared";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [{
      assertion = config.users.mutableUsers;
      message = "Setting `users.users.${cfg.username}.initialPassword` with `users.mutableUsers = true;` is not safe!";
    }];

    users.users.${cfg.username} = {
      isNormalUser = true;

      description = "Jared Baur";

      initialPassword = cfg.username;

      shell = if config.programs.fish.enable then pkgs.fish else null;

      openssh.authorizedKeys.keyFiles = [ pkgs.jmbaur-ssh-keys ];

      extraGroups = [ "wheel" ]
        ++ (lib.optionals config.custom.dev.enable [ "dialout" "plugdev" ])
        ++ (lib.optional config.networking.networkmanager.enable "networkmanager")
        ++ (lib.optional config.programs.adb.enable "adbusers")
        ++ (lib.optional config.programs.flashrom.enable "plugdev")
        ++ (lib.optional config.programs.wireshark.enable "wireshark")
        ++ (lib.optional config.virtualisation.docker.enable "docker")
      ;
    };
  };
}
