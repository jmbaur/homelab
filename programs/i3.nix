{ config, pkgs, ... }:
let
  modifier = "Mod4";
  home-manager = import ../misc/home-manager.nix { ref = "release-21.05"; };
in
{
  home-manager.users.jared.xsession.windowManager.i3 = {
    enable = true;
    config = {
      assigns = {
        "7" = [{ class = "^Firefox$"; }];
        "8" = [{ class = "^Signal$"; }];
        "9" = [{ class = "^Spotify$"; }];
        "10" = [{ class = "^Slack$"; } { class = "^zoom$"; }];
      };
      floating.criteria = [
        { class = "^Sxiv$"; }
        { class = "^mpv$"; }
        { class = "^MuPDF$"; }
        { class = "^zoom$"; }
      ];
      fonts = {
        names = [ "DejaVu Sans Mono" ];
        size = 10.0;
      };
      keybindings = {
        "${modifier}+0" = "workspace number 10";
        "${modifier}+1" = "workspace number 1";
        "${modifier}+2" = "workspace number 2";
        "${modifier}+3" = "workspace number 3";
        "${modifier}+4" = "workspace number 4";
        "${modifier}+5" = "workspace number 5";
        "${modifier}+6" = "workspace number 6";
        "${modifier}+7" = "workspace number 7";
        "${modifier}+8" = "workspace number 8";
        "${modifier}+9" = "workspace number 9";
        "${modifier}+Return" = "exec ${pkgs.kitty}/bin/kitty";
        "${modifier}+Shift+0" = "move container to workspace number 10";
        "${modifier}+Shift+1" = "move container to workspace number 1";
        "${modifier}+Shift+2" = "move container to workspace number 2";
        "${modifier}+Shift+3" = "move container to workspace number 3";
        "${modifier}+Shift+4" = "move container to workspace number 4";
        "${modifier}+Shift+5" = "move container to workspace number 5";
        "${modifier}+Shift+6" = "move container to workspace number 6";
        "${modifier}+Shift+7" = "move container to workspace number 7";
        "${modifier}+Shift+8" = "move container to workspace number 8";
        "${modifier}+Shift+9" = "move container to workspace number 9";
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
        "${modifier}+c" =
          ''exec CM_LAUNCHER=rofi ${pkgs.clipmenu}/bin/clipmenu -fn "DejaVu Sans Mono:10"'';
        "${modifier}+e" = "layout toggle split";
        "${modifier}+f" = "fullscreen toggle";
        "${modifier}+g" =
          "exec i3-input -F '[con_mark=\"%s \"] focus' -l 1 -P 'Goto: '";
        "${modifier}+h" = "focus left";
        "${modifier}+j" = "focus down";
        "${modifier}+k " = "focus up";
        "${modifier}+l" = "focus right";
        "${modifier}+m" = "exec i3-input -F 'mark %s' -l 1 -P 'Mark: '";
        "${modifier}+minus" = "scratchpad show";
        "${modifier}+p" = ''exec ${pkgs.rofi}/bin/rofi -show drun'';
        "${modifier}+r" = "mode resize";
        "${modifier}+s" = "layout stacking";
        "${modifier}+space" = "focus mode_toggle";
        "${modifier}+v" = "split v";
        "${modifier}+w" = "layout tabbed";
        "XF86AudioLowerVolume" =
          "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -10%";
        "XF86AudioMicMute" =
          "exec --no-startup-id pactl set-source-mute @DEFAULT_SOURCE@ toggle";
        "XF86AudioMute" =
          "exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle";
        "XF86AudioRaiseVolume" =
          "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +10%";
        "XF86MonBrightnessDown" = "exec --no-startup-id brightnessctl set 10%-";
        "XF86MonBrightnessUp" = "exec --no-startup-id brightnessctl set +10%";
      };
      modes = { resize = { j = "resize grow height 10 px or 10 ppt"; Escape = "mode default"; "${modifier}+r" = "mode default"; h = "resize shrink width 10 px or 10 ppt"; Return = "mode default"; l = "resize grow width 10 px or 10 ppt"; k = "resize shrink height 10 px or 10 ppt"; }; };
      modifier = modifier;
      workspaceAutoBackAndForth = true;
    };
  };
}
