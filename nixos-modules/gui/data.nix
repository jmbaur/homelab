rec {
  font = "JetBrains Mono";
  cursorTheme = "Adwaita";
  gtkIconTheme = cursorTheme;
  gtkTheme = "${gtkIconTheme}-dark";
  swaylockFlags = [ "--daemonize" "--indicator-caps-lock" "--show-keyboard-layout" "--color" "222222" ];
  colors = {
    modus-vivendi = {
      background = "000000";
      foreground = "ffffff";
      regular0 = "000000";
      regular1 = "ff8059";
      regular2 = "44bc44";
      regular3 = "d0bc00";
      regular4 = "2fafff";
      regular5 = "feacd0";
      regular6 = "00d3d0";
      regular7 = "bfbfbf";
      bright0 = "595959";
      bright1 = "ef8b50";
      bright2 = "70b900";
      bright3 = "c0c530";
      bright4 = "79a8ff";
      bright5 = "b6a0ff";
      bright6 = "6ae4b9";
      bright7 = "ffffff";
    };
    modus-operandi = {
      background = "ffffff";
      foreground = "000000";
      regular0 = "000000";
      bright0 = "585858";
      regular1 = "a60000";
      bright1 = "972500";
      regular2 = "006800";
      bright2 = "316500";
      regular3 = "6f5500";
      bright3 = "884900";
      regular4 = "0031a9";
      bright4 = "354fcf";
      regular5 = "721045";
      bright5 = "531ab6";
      regular6 = "00538b";
      bright6 = "005a5f";
      regular7 = "e1e1e1";
      bright7 = "ffffff";
    };
  };
}
