{ config, pkgs, ... }:
let
  modifier = "Mod4";
  home-manager = import ./home-manager.nix { ref = "release-21.05"; };
in
{
  home-manager.users.jared.xsession.windowManager.i3 = {
    enable = true;
    config = {
      assigns = {
        "7" = [ { class = "^Firefox$"; } ];
        "8" = [ { class = "^Signal$"; } ];
        "9" = [ { class = "^Spotify$"; } ];
        "10" = [ { class = "^Slack$"; } { class = "^zoom$"; } ];
      };
      floating.criteria = [ { class = "^Sxiv$"; } { class = "^mpv$"; } { class = "^MuPDF$"; } { class = "^zoom$"; } ];
      bars = [
        {
          statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ~/.config/i3status-rust/config-okra.toml";
          position = "top";
          fonts = {
            names = [ "DejaVu Sans Mono" ];
            size = 10.0;
          };
        }
      ];
      fonts = {
        names = [ "DejaVu Sans Mono" ];
        size = 10.0;
      };
      keybindings = {
        "${modifier}+0" = "workspace number $ws10";
        "${modifier}+1" = "workspace number $ws1";
        "${modifier}+2" = "workspace number $ws2";
        "${modifier}+3" = "workspace number $ws3";
        "${modifier}+4" = "workspace number $ws4";
        "${modifier}+5" = "workspace number $ws5";
        "${modifier}+6" = "workspace number $ws6";
        "${modifier}+7" = "workspace number $ws7";
        "${modifier}+8" = "workspace number $ws8";
        "${modifier}+9" = "workspace number $ws9";
        "${modifier}+Return" = "exec ${pkgs.kitty}/bin/kitty";
        "${modifier}+Shift+0" = "move container to workspace number $ws10";
        "${modifier}+Shift+1" = "move container to workspace number $ws1";
        "${modifier}+Shift+2" = "move container to workspace number $ws2";
        "${modifier}+Shift+3" = "move container to workspace number $ws3";
        "${modifier}+Shift+4" = "move container to workspace number $ws4";
        "${modifier}+Shift+5" = "move container to workspace number $ws5";
        "${modifier}+Shift+6" = "move container to workspace number $ws6";
        "${modifier}+Shift+7" = "move container to workspace number $ws7";
        "${modifier}+Shift+8" = "move container to workspace number $ws8";
        "${modifier}+Shift+9" = "move container to workspace number $ws9";
        "${modifier}+Shift+c" = "reload";
        "${modifier}+Shift+e" = "exit";
        "${modifier}+Shift+h" = "move left";
        "${modifier}+Shift+j" = "move down";
        "${modifier}+Shift+k" = "move up";
        "${modifier}+Shift+l" = "move right";
        "${modifier}+Shift+minus" = "move scratchpad";
        "${modifier}+Shift+q" = "kill";
        "${modifier}+Shift+r" = "restart";
        "${modifier}+Shift+space" = "floating toggle";
        "${modifier}+Tab" = "workspace back_and_forth";
        "${modifier}+a" = "focus parent";
        "${modifier}+b" = "split h";
        "${modifier}+c" = "exec ${pkgs.clipmenu}/bin/clipmenu -fn \"DejaVu Sans Mono:10\"";
        "${modifier}+e" = "layout toggle split";
        "${modifier}+f" = "fullscreen toggle";
        "${modifier}+g" = "exec i3-input -F '[con_mark=\"%s \"] focus' -l 1 -P 'Goto: '";
        "${modifier}+h" = "focus left";
        "${modifier}+j" = "focus down";
        "${modifier}+k " = "focus up";
        "${modifier}+l" = "focus right";
        "${modifier}+m" = "exec i3-input -F 'mark %s' -l 1 -P 'Mark: '";
        "${modifier}+minus" = "scratchpad show";
        "${modifier}+p" = "exec ${pkgs.dmenu}/bin/dmenu_run -fn \"DejaVu Sans Mono:10\" -l 10";
        "${modifier}+r" = "mode \"resize\"";
        "${modifier}+s" = "layout stacking";
        "${modifier}+space" = "focus mode_toggle";
        "${modifier}+v" = "split v";
        "${modifier}+w" = "layout tabbed";
        "XF86AudioLowerVolume" = "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -10%";
        "XF86AudioMicMute" = "exec --no-startup-id pactl set-source-mute @DEFAULT_SOURCE@ toggle";
        "XF86AudioMute" = "exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle";
        "XF86AudioRaiseVolume" = "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +10%";
        "XF86MonBrightnessDown" = "exec --no-startup-id brightnessctl set 10%-";
        "XF86MonBrightnessUp" = "exec --no-startup-id brightnessctl set +10%";
      };
      modifier = modifier;
      workspaceAutoBackAndForth = true;
    };
  };
}
