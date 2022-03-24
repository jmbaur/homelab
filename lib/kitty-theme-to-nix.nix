{ lib, kitty-themes }:
let
  lines = lib.splitString "\n"
    (builtins.readFile "${kitty-themes}/themes/modus-vivendi.conf");
  noComments = lib.filter
    (line:
      line != "" && !(lib.hasPrefix "#" line))
    lines;
  noExtraWhitespace = builtins.map
    (line:
      lib.filter (item: item != "") (lib.splitString " " line))
    noComments;
  listOfAttrs = builtins.map
    (line: {
      name = "${builtins.elemAt line 0}";
      value = "${builtins.elemAt line 1}";
    })
    noExtraWhitespace;
  theme = builtins.listToAttrs listOfAttrs;
  theme-no-octothorpe = lib.mapAttrs (name: value: lib.removePrefix "#" value) theme;
in
{ inherit theme theme-no-octothorpe; }
