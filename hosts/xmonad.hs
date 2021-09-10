import qualified Data.Map                as M
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
