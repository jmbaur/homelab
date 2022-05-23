{ config, lib, pkgs, ... }:
let
  cfg = config.custom.jared;
in
{
  options.custom.jared.enable = lib.mkEnableOption "Enable jared user";
  config = lib.mkIf cfg.enable {
    programs.zsh = {
      enable = true;
      interactiveShellInit = "bindkey -e";
    };

    users.users.jared = {
      isNormalUser = true;
      description = "Jared Baur";
      shell = pkgs.zsh;
      extraGroups = [
        "dialout" # picocom
        "wheel" # sudo
        (lib.optionalString config.hardware.i2c.enable "i2c")
        (lib.optionalString config.networking.networkmanager.enable "networkmanager")
        (lib.optionalString config.programs.adb.enable "adbusers")
      ];
      openssh.authorizedKeys.keyFiles = [ (import ../../data/jmbaur-ssh-keys.nix) ];
    };

    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
      users.jared = import ../../homes/jared;
    };
  };
}
