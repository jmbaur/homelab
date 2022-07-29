inputs: with inputs;
let
  mkSystemNode = { name, hostname, system }: {
    inherit hostname;
    profiles.system = {
      sshUser = "root";
      path = deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.${name};
    };
  };
  nodes = builtins.listToAttrs [
    { name = "artichoke"; value = mkSystemNode { name = "artichoke"; hostname = "artichoke.mgmt.home.arpa"; system = "aarch64-linux"; }; }
    { name = "beetroot"; value = mkSystemNode { name = "beetroot"; hostname = "beetroot.mgmt.home.arpa"; system = "aarch64-linux"; }; }
    { name = "kale"; value = mkSystemNode { name = "kale"; hostname = "kale.mgmt.home.arpa"; system = "aarch64-linux"; }; }
    { name = "okra"; value = mkSystemNode { name = "okra"; hostname = "okra.mgmt.home.arpa"; system = "x86_64-linux"; }; }
    { name = "potato"; value = mkSystemNode { name = "potato"; hostname = "potato.mgmt.home.arpa"; system = "x86_64-linux"; }; }
    { name = "rhubarb"; value = mkSystemNode { name = "rhubarb"; hostname = "rhubarb.mgmt.home.arpa"; system = "aarch64-linux"; }; }
  ];
in
{
  inherit nodes;
}
