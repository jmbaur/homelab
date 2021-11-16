{ pkgs ? import <nixpkgs> { } }:
with pkgs;
let
  kanshi-config = writeTextFile
    {
      name = "kanshi-config";
      text = ''
        profile docked {
          output eDP-1 disable
          output "Lenovo Group Limited LEN P24q-20 V306P4GR" mode 2560x1440@74.780Hz position 0,0
        }
        profile laptop {
          output eDP-1 enable
        }
      '';
    };
in
symlinkJoin {
  name = "kanshi";
  paths = [ kanshi ];
  buildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/kanshi \
      --add-flags "--config=${kanshi-config}"
  '';
}
