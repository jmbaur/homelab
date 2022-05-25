{ config, lib, pkgs, ... }:
let
  cfg = config.custom.jared;
in
{
  options.custom.jared = {
    enable = lib.mkEnableOption "Enable jared user";
    includeHomeManager = lib.mkEnableOption "Enable home-manager for jared user";
  };
  config = lib.mkIf cfg.enable {
    users.users.jared = {
      isNormalUser = true;
      description = "Jared Baur";
      openssh.authorizedKeys.keyFiles = [
        (import ../../data/jmbaur-ssh-keys.nix)
      ];
      shell =
        if config.programs.zsh.enable then
          pkgs.zsh
        else
          pkgs.bashInteractive;
      extraGroups = [
        "dialout" # picocom
        "wheel" # sudo
      ]
      ++ (lib.optional config.hardware.i2c.enable "i2c")
      ++ (lib.optional config.networking.networkmanager.enable "networkmanager")
      ++ (lib.optional config.programs.adb.enable "adbusers");
    };

    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
      users.jared = lib.mkIf cfg.includeHomeManager {
        imports =
          [ ./home-manager/common.nix ]
          ++
          lib.optional config.custom.gui.enable ./home-manager/gui.nix
          ++
          lib.optional config.custom.containers.enable ./home-manager/dev.nix;
      };
    };
  };
}
