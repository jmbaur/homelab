{ pkgs, configs, ... }:
let home-manager = import ./home-manager.nix { ref = "release-21.05"; };
in {
  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url =
        "https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz";
    }))
  ];
  environment.systemPackages = [ pkgs.neovim-nightly ];
  home-manager.users.jared.xdg.configFile."nvim/init.lua".source = ./init.lua;
}
