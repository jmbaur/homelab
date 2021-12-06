{ writeText, pulseaudio, kitty, brightnessctl }:
writeText "i3-config" ''
  set $mod    Mod4
  set $left   h
  set $down   j
  set $up     k
  set $right  l
  set $ws1    "1"
  set $ws2    "2"
  set $ws3    "3"
  set $ws4    "4"
  set $ws5    "5"
  set $ws6    "6"
  set $ws7    "7"
  set $ws8    "8"
  set $ws9    "9"
  set $ws10   "10"

  floating_modifier $mod
  font pango:Rec Mono Linear 10
  hide_edge_borders smart
  workspace_auto_back_and_forth yes

  for_window [all] title_window_icon on

  bindsym $mod+Tab workspace back_and_forth

  bindsym $mod+minus scratchpad show
  bindsym $mod+Shift+minus move scratchpad

  bindsym XF86AudioRaiseVolume exec --no-startup-id ${pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +10%
  bindsym XF86AudioLowerVolume exec --no-startup-id ${pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -10%
  bindsym XF86AudioMute exec --no-startup-id ${pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle
  bindsym XF86AudioMicMute exec --no-startup-id ${pulseaudio}/bin/pactl set-source-mute @DEFAULT_SOURCE@ toggle
  bindsym XF86MonBrightnessDown exec --no-startup-id ${brightnessctl}/bin/brightnessctl set 10%-
  bindsym XF86MonBrightnessUp exec --no-startup-id ${brightnessctl}/bin/brightnessctl set +10%

  bindsym $mod+Return exec ${kitty}/bin/kitty

  bindsym $mod+Shift+q kill

  bindsym $mod+p exec --no-startup-id dmenu_run -fn Rec\ Mono\ Linear

  bindsym $mod+c exec --no-startup-id clipmenu -fn Rec\ Mono\ Linear

  bindsym $mod+$left focus left
  bindsym $mod+$down focus down
  bindsym $mod+$up focus up
  bindsym $mod+$right focus right
  bindsym $mod+Left focus left
  bindsym $mod+Down focus down
  bindsym $mod+Up focus up
  bindsym $mod+Right focus right

  bindsym $mod+Shift+$left move left
  bindsym $mod+Shift+$down move down
  bindsym $mod+Shift+$up move up
  bindsym $mod+Shift+$right move right
  bindsym $mod+Shift+Left move left
  bindsym $mod+Shift+Down move down
  bindsym $mod+Shift+Up move up
  bindsym $mod+Shift+Right move right

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
          bindsym $left resize shrink width 10 px or 10 ppt
          bindsym $down resize grow height 10 px or 10 ppt
          bindsym $up resize shrink height 10 px or 10 ppt
          bindsym $right resize grow width 10 px or 10 ppt

          bindsym Left resize shrink width 10 px or 10 ppt
          bindsym Down resize grow height 10 px or 10 ppt
          bindsym Up resize shrink height 10 px or 10 ppt
          bindsym Right resize grow width 10 px or 10 ppt

          bindsym Return mode "default"
          bindsym Escape mode "default"
          bindsym $mod+r mode "default"
  }

  bindsym $mod+r mode "resize"

  bar {
          mode hide
          position bottom
          status_command i3status
          tray_output primary
  }
''
