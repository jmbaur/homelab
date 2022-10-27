{ lib, config, pkgs, ... }:
let cfg = config.custom.users.jared; in
{
  options.custom.users.jared = {
    enable = lib.mkEnableOption "jared";
    passwordFile = lib.mkOption { type = lib.types.path; };
  };
  config = lib.mkIf cfg.enable {
    users.users.jared = {
      inherit (cfg) passwordFile;
      isNormalUser = true;
      description = "Jared Baur";
      shell = pkgs.zsh;
      openssh.authorizedKeys.keyFiles = [ pkgs.jmbaur-github-ssh-keys ];
      extraGroups = [ "dialout" "wheel" ]
        ++ (lib.optional config.networking.networkmanager.enable "networkmanager")
        ++ (lib.optional config.programs.wireshark.enable "wireshark")
        ++ (lib.optional config.programs.adb.enable "adbusers")
        ++ (lib.optional config.virtualisation.docker.enable "docker")
      ;
    };
  };
}
