{ config, lib, pkgs, ... }:
let
  cfg = config.custom.jared;
in
{
  options.custom.jared.enable = lib.mkEnableOption "Enable jared user";
  config = lib.mkIf cfg.enable {
    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
      users.jared = import ../../homes/jared;
    };
    users = {
      users.jared = {
        isNormalUser = true;
        description = "Jared Baur";
        shell = pkgs.zsh;
        extraGroups = [
          "adbusers" # adb
          "dialout" # picocom
          "wheel" # sudo
          "wireshark" # wireshark
        ];
      };
    };
  };
}
