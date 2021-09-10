import qualified Data.Map                     as M
import           Graphics.X11.ExtraTypes.XF86
import           XMonad
import           XMonad.Hooks.DynamicLog
import           XMonad.Hooks.ManageDocks
import           XMonad.Layout.NoBorders
import           XMonad.Prompt
import           XMonad.Prompt.Shell
import           XMonad.Prompt.Ssh
import           XMonad.Prompt.XMonad
import           XMonad.Util.Run

joinWith :: [String] -> String -> String
joinWith xs sep = concat . init . concat $ [[x, sep] | x <- xs]

main = do
  h <- spawnPipe $ joinWith ["xmobar", "-F", "\"" ++ fg ++ "\"", "-B", "\"" ++ bg ++ "\""] " "
  xmonad $ docks $ def
    { terminal = myTerminal
    , focusFollowsMouse = True
    , modMask = mod4Mask
    , borderWidth = 2
    , normalBorderColor = bg
    , focusedBorderColor = blue
    , keys = myKeys <+> keys def
    , manageHook = manageDocks <+> manageHook def
    , layoutHook = avoidStruts $ smartBorders $ layoutHook def
    , logHook = dynamicLogWithPP xmobarPP
      { ppCurrent = xmobarColor fg bg2 . wrap " " " "
      , ppVisible = wrap " " " "
      , ppTitle = xmobarColor green ""
      , ppOutput = hPutStrLn h
      }
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
    , bgColor = bg
    , fgColor = fg
    , bgHLight = bg2
    , fgHLight = fg
    , position = Top
    }

myTerminal = "kitty"
bg = "#282828"
bg2 = "#504945"
fg = "#ebdbb2"
green = "#98971a"
blue = "#458588"
red = "#cc241d"
