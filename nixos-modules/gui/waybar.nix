{
  height = 34;
  spacing = 4;
  battery = {
    format = "{capacity}% {icon}";
    format-icons = [ "" "" "" "" "" ];
    interval = 60;
    max-length = 25;
    states = {
      critical = 15;
      warning = 30;
    };
  };
  clock = { format = "{:%F   %H:%M}"; };
  memory = { format = "{}% "; interval = 30; max-length = 10; };
  modules-center = [ "clock" ];
  modules-left = [ "wlr/taskbar" ];
  modules-right = [ "network" "memory" "battery" "privacy" "tray" ];
  network = {
    format = "{ifname}";
    format-disconnected = "";
    format-ethernet = "{ifname} ";
    format-wifi = "{essid} ";
    max-length = 50;
    tooltip-format = "{ifname}";
    tooltip-format-disconnected = "Disconnected ⚠";
    tooltip-format-ethernet = "{ifname} ";
    tooltip-format-wifi = "{essid} ({signalStrength}%) ";
  };
  "wlr/taskbar" = {
    format = "{icon}";
    icon-size = 14;
    icon-theme = "Numix-Circle";
    on-click = "activate";
    on-click-middle = "close";
    tooltip-format = "{title}";
  };
  privacy = {
    icon-spacing = 4;
    icon-size = 18;
    transition-duration = 250;
    modules = [
      {
        type = "screenshare";
        tooltip = true;
        tooltip-icon-size = 24;
      }
      {
        type = "audio-out";
        tooltip = true;
        tooltip-icon-size = 24;
      }
      {
        type = "audio-in";
        tooltip = true;
        tooltip-icon-size = 24;
      }
    ];
  };
  tray = {
    icon-size = 21;
    spacing = 10;
  };
}
