import qualified Data.Map                     as M
import           Graphics.X11.ExtraTypes.XF86
import           XMonad
import           XMonad.Hooks.DynamicLog
import           XMonad.Prompt
import           XMonad.Prompt.Shell
import           XMonad.Prompt.Ssh
import           XMonad.Prompt.XMonad

main = xmonad =<< xmobar myConfig

myConfig =
  def
    { terminal = "kitty"
    , focusFollowsMouse = True
    , modMask = mod4Mask
    , borderWidth = 2
    , normalBorderColor = "#474646"
    , focusedBorderColor = "#83a598"
    , keys = myKeys <+> keys def
    }

myKeys conf@(XConfig {XMonad.modMask = modm}) =
  M.fromList
    [ ((modm, xK_x), xmonadPrompt myXPConfig)
    , ((modm, xK_p), shellPrompt myXPConfig)
    , ((modm, xK_s), sshPrompt myXPConfig)
    , ((0, xF86XK_AudioRaiseVolume), spawn "pactl set-sink-volume @DEFAULT_SINK@ +5%")
    , ((0, xF86XK_AudioLowerVolume), spawn "pactl set-sink-volume @DEFAULT_SINK@ -5%")
    , ((0, xF86XK_AudioMute), spawn "pactl set-sink-mute @DEFAULT_SINK@ toggle")
    , ((0, xF86XK_AudioMicMute), spawn "pactl set-source-mute @DEFAULT_SOURCE@ toggle")
    , ((0, xF86XK_MonBrightnessUp), spawn "brightnessctl set +10%")
    , ((0, xF86XK_MonBrightnessDown), spawn "brightnessctl set 10%-")
    ]

myXPConfig =
  def
    { font = "xft:Hack:pixelsize=14"
    , bgColor = "#282828"
    , fgColor = "#ebdbb2"
    , bgHLight = "#474646"
    , fgHLight = "#ebdbb2"
    , borderColor = "#83a598"
    , position = Top
    }
