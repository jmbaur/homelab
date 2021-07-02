{ config, lib, pkgs, ... }:

{
  home-manager.users.jared.home.file.".config/i3/config".text = ''
    set $mod Mod4
    font pango:Hack 12

    focus_follows_mouse yes

    exec --no-startup-id ${pkgs.autorandr}/bin/autorandr -c --default laptop

    bindsym XF86AudioRaiseVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +10% && $refresh_i3status
    bindsym XF86AudioLowerVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -10% && $refresh_i3status
    bindsym XF86AudioMute exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle && $refresh_i3status
    bindsym XF86AudioMicMute exec --no-startup-id pactl set-source-mute @DEFAULT_SOURCE@ toggle && $refresh_i3status
    bindsym XF86MonBrightnessDown exec --no-startup-id brightnessctl set 5%-
    bindsym XF86MonBrightnessUp exec --no-startup-id brightnessctl set +5%
    bindsym $mod+backslash exec --no-startup-id "CM_LAUNCHER=rofi clipmenu"
    bindsym $mod+p exec --no-startup-id "rofi -modi drun,ssh -show drun"
    bindsym $mod+Return exec kitty
    bindsym $mod+Shift+q kill

    floating_modifier $mod

    bindsym $mod+h focus left
    bindsym $mod+j focus down
    bindsym $mod+k focus up
    bindsym $mod+l focus right

    bindsym $mod+Shift+h move left
    bindsym $mod+Shift+j move down
    bindsym $mod+Shift+k move up
    bindsym $mod+Shift+l move right

    bindsym $mod+b split h
    bindsym $mod+v split v

    bindsym $mod+f fullscreen toggle

    bindsym $mod+s layout stacking
    bindsym $mod+w layout tabbed
    bindsym $mod+e layout toggle split

    bindsym $mod+Shift+space floating toggle
    bindsym $mod+space focus mode_toggle

    bindsym $mod+a focus parent
    bindsym $mod+d focus child

    set $ws1 "1"
    set $ws2 "2"
    set $ws3 "3"
    set $ws4 "4"
    set $ws5 "5"
    set $ws6 "6"
    set $ws7 "7"
    set $ws8 "8"
    set $ws9 "9"
    set $ws10 "10"

    bindsym $mod+1 workspace number $ws1
    bindsym $mod+2 workspace number $ws2
    bindsym $mod+3 workspace number $ws3
    bindsym $mod+4 workspace number $ws4
    bindsym $mod+5 workspace number $ws5
    bindsym $mod+6 workspace number $ws6
    bindsym $mod+7 workspace number $ws7
    bindsym $mod+8 workspace number $ws8
    bindsym $mod+9 workspace number $ws9
    bindsym $mod+0 workspace number $ws10

    bindsym $mod+Shift+1 move container to workspace number $ws1
    bindsym $mod+Shift+2 move container to workspace number $ws2
    bindsym $mod+Shift+3 move container to workspace number $ws3
    bindsym $mod+Shift+4 move container to workspace number $ws4
    bindsym $mod+Shift+5 move container to workspace number $ws5
    bindsym $mod+Shift+6 move container to workspace number $ws6
    bindsym $mod+Shift+7 move container to workspace number $ws7
    bindsym $mod+Shift+8 move container to workspace number $ws8
    bindsym $mod+Shift+9 move container to workspace number $ws9
    bindsym $mod+Shift+0 move container to workspace number $ws10

    bindsym $mod+Shift+c reload
    bindsym $mod+Shift+r restart
    bindsym $mod+Shift+e exit

    mode "resize" {
            bindsym h resize shrink width 10 px or 10 ppt
            bindsym j resize grow height 10 px or 10 ppt
            bindsym k resize shrink height 10 px or 10 ppt
            bindsym l resize grow width 10 px or 10 ppt

            bindsym Return mode "default"
            bindsym Escape mode "default"
            bindsym $mod+r mode "default"
    }

    bindsym $mod+r mode "resize"

    bindsym $mod+Shift+minus move scratchpad
    bindsym $mod+minus scratchpad show

    workspace_auto_back_and_forth yes
    bindsym $mod+Tab workspace back_and_forth

    bindsym $mod+m exec i3-input -F 'mark %s' -l 1 -P 'Mark: '
    bindsym $mod+Shift+m exec i3-input -F 'unmark %s' -l 1 -P 'Unmark: '
    bindsym $mod+g exec i3-input -F '[con_mark="%s"] focus' -l 1 -P 'Goto: '

    # $i3-status
    # color_bad = "#CC0000"
    # color_degraded = "#EDD400"
    # color_good = "#73D216"

    # $i3-theme-window
    # tango dark
    set $darkblue 		#204A87
    set $darkbrown		#8F5902
    set $darkgreen 		#4E9A06
    set $darkmagenta 	#5C3566
    set $darkred 		#A40000
    set $darkyellow 	#C4A000
    set $darkorange		#CE5C00

    # tango light
    set $lightblue 		#729FCF
    set $lightbrown		#E9B96E
    set $lightgreen 	#8AE234
    set $lightmagenta 	#AD7FA8
    set $lightred 		#EF2929
    set $lightyellow 	#FCE94F
    set $lightorange	#FCAF3E

    # tango normal
    set $blue 		#3465A4
    set $brown		#C17D11
    set $green 		#73D216
    set $magenta 		#75507B
    set $red 		#CC0000
    set $yellow 		#EDD400
    set $orange		#F57900

    # tango mono
    set $black 		#555753
    set $grey		#BABDB6
    set $white 		#EEEEEC
    set $darkblack 		#2E3436
    set $darkgrey 		#888A85
    set $darkwhite 		#D3D7CF

    # tango <clientclass> <border> <backg> <text> <indicator>
    client.focused          $blue $darkblue $white $blue
    client.focused_inactive $darkgrey $black $grey $darkgrey
    client.unfocused        $black $darkblack $grey $darkgrey
    client.urgent           $lightred $red $white $lightred

    bar {
      position top
      status_command i3status-rs $HOME/.config/i3status-rust/config-top.toml

      colors {
        # tango <workclass> <border> <backg> <text>
        focused_workspace 	$blue $darkblue $white
        active_workspace 	$grey $darkgrey $grey
        inactive_workspace	$black $darkblack $grey
        urgent_workspace 	$red $darkred $white
        background #222222
        separator  #444444
        statusline $darkgrey
      }
    }
  '';
}
