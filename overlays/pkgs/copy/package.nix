{ writeShellScriptBin }: writeShellScriptBin "copy" ''printf "\033]52;c;$(base64)\07"''
