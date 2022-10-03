inputs: with inputs;
let
  mkSystemNode = { name, hostname, system, magicRollback ? true, autoRollback ? true }: {
    inherit hostname magicRollback autoRollback;
    profiles.system = {
      sshUser = "root";
      path = deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.${name};
    };
  };
  nodes = builtins.listToAttrs [
    # { name = "beetroot"; value = mkSystemNode { name = "beetroot"; hostname = "beetroot.mgmt.home.arpa"; system = "aarch64-linux"; }; }
    # { name = "potato"; value = mkSystemNode { name = "potato"; hostname = "potato.mgmt.home.arpa"; system = "x86_64-linux"; }; }
    { name = "artichoke"; value = mkSystemNode { name = "artichoke"; hostname = "artichoke.mgmt.home.arpa"; system = "aarch64-linux"; }; }
    { name = "kale"; value = mkSystemNode { name = "kale"; hostname = "kale.mgmt.home.arpa"; system = "aarch64-linux"; }; }
    { name = "okra"; value = mkSystemNode { name = "okra"; hostname = "okra.trusted.home.arpa"; system = "x86_64-linux"; }; }
    { name = "rhubarb"; value = mkSystemNode { name = "rhubarb"; hostname = "rhubarb.mgmt.home.arpa"; system = "aarch64-linux"; magicRollback = false; }; }
    { name = "www"; value = mkSystemNode { name = "www"; hostname = "www.jmbaur.com"; system = "aarch64-linux"; }; }
  ];
in
{
  inherit nodes;
}
