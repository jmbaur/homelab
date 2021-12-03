self: super:

let
  kitty-themes = super.fetchFromGitHub {
    owner = "dexpota";
    repo = "kitty-themes";
    rev = "fca3335489bdbab4cce150cb440d3559ff5400e2";
    sha256 = "sha256-DBvkVxInRhKhx5S7dzz5bcSFCf1h6A27h+lIPIXLr4U=";
  };
  kitty-config = super.writeTextFile {
    name = "kitty-config";
    text = ''
      copy_on_select yes
      disable_ligatures always
      enable_audio_bell no
      font_family Iosevka
      font_size 16
      term xterm-256color
      update_check_interval 0
      ${builtins.readFile "${kitty-themes}/themes/gruvbox_dark.conf"}
    '';
  };
in
{
  kitty = super.kitty.overrideAttrs (old: {
    postInstall = ''
      ${old.postInstall}
      wrapProgram $out/bin/kitty \
        --add-flags "--config=${kitty-config}"
    '';
  });
}
