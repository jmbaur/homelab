inputs:
let
  mkSystemNode = { name, hostname, magicRollback ? true, autoRollback ? true }: {
    inherit hostname magicRollback autoRollback;
    profiles.system = {
      sshUser = "root";
      path =
        let
          pkgs = import inputs.nixpkgs {
            crossSystem = inputs.self.nixosConfigurations.${name}.config.nixpkgs.hostPlatform;
            localSystem = "x86_64-linux";
            overlays = [ inputs.deploy-rs.overlay ];
          };
        in
        pkgs.deploy-rs.lib.activate.nixos inputs.self.nixosConfigurations.${name};
    };
  };
  nodes = builtins.listToAttrs [
    { name = "kale"; value = mkSystemNode { name = "kale"; hostname = "kale.home.arpa"; }; }
    { name = "okra"; value = mkSystemNode { name = "okra"; hostname = "okra.home.arpa"; }; }
    { name = "rhubarb"; value = mkSystemNode { name = "rhubarb"; hostname = "rhubarb.home.arpa"; magicRollback = false; }; }
    { name = "www"; value = mkSystemNode { name = "www"; hostname = "www.jmbaur.com"; }; }
  ];
in
{
  inherit nodes;
}
