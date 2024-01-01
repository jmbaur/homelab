inputs:

let
  inherit (inputs.nixpkgs.lib) flatten filterAttrs mapAttrsToList nameValuePair;
in
builtins.listToAttrs (flatten (
  mapAttrsToList
    (userName: _:

    mapAttrsToList
      (hostName: _:

      let
        inherit (import ./${userName}/${hostName}) system modules;
      in
      nameValuePair "${userName}-${hostName}" (inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [ inputs.self.overlays.default ];
        };
        modules = [ inputs.self.homeModules.jared ] ++ modules;
      }))
      (filterAttrs (_: entryType: entryType == "directory") (builtins.readDir ./${userName})))
    (filterAttrs (_: entryType: entryType == "directory") (builtins.readDir ./.))
))
