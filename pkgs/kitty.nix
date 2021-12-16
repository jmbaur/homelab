self: super:

let
  kitty-themes = super.fetchFromGitHub {
    owner = "dexpota";
    repo = "kitty-themes";
    rev = "fca3335489bdbab4cce150cb440d3559ff5400e2";
    sha256 = "sha256-DBvkVxInRhKhx5S7dzz5bcSFCf1h6A27h+lIPIXLr4U=";
  };
  kitty-config = super.writeText "kitty-config" ''
    copy_on_select yes
    disable_ligatures always
    enable_audio_bell no
    font_family Rec Mono Linear
    font_size 12
    term xterm-256color
    update_check_interval 0
    ${builtins.readFile "${kitty-themes}/themes/gruvbox_dark.conf"}
  '';
in
{
  kitty = super.symlinkJoin {
    inherit (super.kitty) name;
    paths = [ super.kitty ];
    buildInputs = [ super.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/kitty \
        --add-flags "--config=${kitty-config}"
    '';
  };
}
