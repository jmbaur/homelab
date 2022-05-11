{ config, lib, pkgs, ... }:
let
  cfg = config.custom.jared;
in
{
  options.custom.jared.enable = lib.mkEnableOption "Enable jared user";
  config = lib.mkIf cfg.enable {
    users.users.jared = {
      isNormalUser = true;
      description = "Jared Baur";
      extraGroups = [
        "dialout" # picocom
        "wheel" # sudo
        (lib.optionalString config.hardware.i2c.enable "i2c")
        (lib.optionalString config.programs.adb.enable "adbusers")
      ];
      openssh.authorizedKeys.keyFiles = lib.mkIf config.custom.deploy.enable [ (import ../../data/jmbaur-ssh-keys.nix) ];
    };

    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
      users.jared = import ../../homes/jared;
    };
  };
}
