{ config, lib, nixosConfig, ... }:
let
  cfg = config.custom.common;
in
with lib; {
  options.custom.common = {
    enable = mkOption {
      type = types.bool;
      default = nixosConfig.custom.common.enable;
    };
  };
  config = mkIf cfg.enable {
    home.stateVersion = nixosConfig.system.stateVersion;

    nixpkgs.config.allowUnfree = true;

    home.shellAliases = {
      ls = "ls --color=auto";
      grep = "grep --color=auto";
      r = "stty sane && reset";
    };

    programs.dircolors.enable = true;
  };
}
