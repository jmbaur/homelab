{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.custom.foot;
  foot = builtins.fetchGit {
    url = "https://codeberg.org/dnkl/foot";
    rev = "9a04c741a094b97f4502d4c098fca8c19cb3647b";
  };
  tempus-night = "${foot}/themes/tempus-night";
in
{

  options = {
    custom.foot = {
      enable = mkOption {
        type = types.bool;
        default = config.custom.sway.enable;
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.foot ];
    environment.etc."xdg/foot/foot.ini".text = ''
      [main]
      font=Hack:size=8
      term=xterm-256color
      selection-target=both
      [mouse]
      hide-when-typing=yes
      ${builtins.readFile tempus-night}
    '';
  };

}
