self: super:
let
  alacritty-themes = super.fetchFromGitHub {
    owner = "rajasegar";
    repo = "alacritty-themes";
    rev = "66df148c7be3224b926e5ca470a452ec6d5a0e25";
    sha256 = "sha256-2/xUmSFqgaQuy1kMmHXIDhyC4YnDLlaxab4qCJYrV0E=";
  };
  alacritty-config = super.writeTextFile {
    name = "alacritty-config";
    text = ''
      env:
        TERM: xterm-256color

      font:
        normal:
          family: Iosevka
          style: Regular
        bold:
          family: Iosevka
          style: Bold
        italic:
          family: Iosevka
          style: Italic
        bold_italic:
          family: Iosevka
          style: Bold Italic
        size: 14

      ${builtins.readFile "${alacritty-themes}/themes/Gruvbox-Dark.yml"}
    '';
  };
in
{
  alacritty = super.alacritty.overrideAttrs (old: {
    postInstall = ''
      ${old.postInstall}
      wrapProgram $out/bin/alacritty \
        --add-flags "--config-file=${alacritty-config}"
    '';
  });
}
