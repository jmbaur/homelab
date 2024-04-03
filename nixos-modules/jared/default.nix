{
  lib,
  config,
  pkgs,
  ...
}:
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
    includePersonalConfigs = lib.mkEnableOption "personal configs" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.users.mutableUsers;
        message = "Setting `users.users.${cfg.username}.initialPassword` with `users.mutableUsers = false;` is not safe!";
      }
    ];

    users.users.${cfg.username} = {
      isNormalUser = true;

      description = "Jared Baur";

      initialPassword = cfg.username;

      shell = if config.programs.fish.enable then pkgs.fish else null;

      openssh.authorizedKeys.keyFiles = lib.optional cfg.includePersonalConfigs pkgs.jmbaur-ssh-keys;

      extraGroups =
        [ "wheel" ]
        ++ (lib.optional config.custom.dev.enable "dialout")
        ++ (lib.optional config.networking.networkmanager.enable "networkmanager")
        ++ (lib.optional config.programs.adb.enable "adbusers")
        ++ (lib.optional config.programs.flashrom.enable "plugdev")
        ++ (lib.optional config.programs.wireshark.enable "wireshark")
        ++ (lib.optional config.virtualisation.docker.enable "docker");
    };
  };
}
