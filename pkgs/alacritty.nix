self: super:
let
  alacritty-themes = super.fetchFromGitHub {
    owner = "rajasegar";
    repo = "alacritty-themes";
    rev = "66df148c7be3224b926e5ca470a452ec6d5a0e25";
    sha256 = "sha256-2/xUmSFqgaQuy1kMmHXIDhyC4YnDLlaxab4qCJYrV0E=";
  };
  alacritty-config = super.writeText "alacritty-config" ''
    env:
      TERM: xterm-256color

    font:
      normal:
        family: Rec Mono Linear
        style: Regular
      bold:
        family: Rec Mono Linear
        style: Bold
      italic:
        family: Rec Mono Linear
        style: Italic
      bold_italic:
        family: Rec Mono Linear
        style: Bold Italic
      size: 8

    ${builtins.readFile "${alacritty-themes}/themes/Gruvbox-Dark.yml"}
  '';
in
{
  alacritty = super.symlinkJoin {
    inherit (super.alacritty) name;
    paths = [ super.alacritty ];
    buildInputs = [ super.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/alacritty \
        --add-flags "--config-file=${alacritty-config}"
    '';
  };
}
