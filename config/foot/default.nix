{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.custom.foot;
  foot = builtins.fetchGit {
    url = "https://codeberg.org/dnkl/foot";
    rev = "9a04c741a094b97f4502d4c098fca8c19cb3647b";
  };
in
{

  options = {
    custom.foot = {
      enable = mkOption {
        type = types.bool;
        default = false;
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

      [cursor]
      color=ffffea 000000

      [colors]
      foreground=000000
      background=ffffea
      regular0=000000
      regular1=ad4f4f
      regular2=468747
      regular3=8f7734
      regular4=268bd2
      regular5=888aca
      regular6=6aa7a8
      regular7=f3f3d3
      bright0=878781
      bright1=ffdddd
      bright2=ebffeb
      bright3=edeea5
      bright4=ebffff
      bright5=96d197
      bright6=a1eeed
      bright7=ffffeb
    '';
  };

}
