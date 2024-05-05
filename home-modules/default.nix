inputs:

let
  inherit (inputs.nixpkgs.lib) filterAttrs mapAttrs;
in
mapAttrs (userName: _: {
  imports = [ ./${userName} ];
  _module.args = {
    inherit inputs;
  };
}) (filterAttrs (_: entryType: entryType == "directory") (builtins.readDir ./.))
