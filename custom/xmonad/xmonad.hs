import qualified Data.Map as M
import XMonad
import XMonad.Prompt
import XMonad.Prompt.Pass
import XMonad.Prompt.Shell

main =
  xmonad $
    def
      { modMask = mod4Mask,
        terminal = "kitty",
        keys = myKeys <+> keys def
      }

myKeys conf@XConfig {XMonad.modMask = modm} =
  M.fromList
    [ ((modm, xK_p), shellPrompt myXPConfig),
      ((modm .|. shiftMask, xK_p), passPrompt myXPConfig),
      ((modm, xK_q), restart "xmonad" True)
    ]

myXPConfig :: XPConfig
myXPConfig =
  def
    { font = "xft:monospace:size=12",
      promptBorderWidth = 0,
      position = Top,
      height = 22
    }
