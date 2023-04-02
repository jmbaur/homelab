inputs:
let
  mkSystemNode = { name, hostname, magicRollback ? true, autoRollback ? true }: {
    inherit name;
    value = {
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
  };
  nodes = builtins.listToAttrs [
    (mkSystemNode { name = "kale"; hostname = "kale.home.arpa"; })
    (mkSystemNode { name = "okra"; hostname = "okra.home.arpa"; })
    (mkSystemNode { name = "rhubarb"; hostname = "rhubarb.home.arpa"; magicRollback = false; })
    (mkSystemNode { name = "www"; hostname = "www.jmbaur.com"; })
  ];
in
{
  inherit nodes;
}
