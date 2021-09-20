{ pkgs, configs, ... }:
let
  home-manager = import ./home-manager.nix { ref = "release-21.05"; };
in
{
  nixpkgs.overlays = [
    (
      import (
        builtins.fetchTarball {
          url =
            "https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz";
        }
      )
    )
  ];
  environment.systemPackages = [ pkgs.neovim-nightly ];
  home-manager.users.jared.programs.neovim = {
    enable = true;
    package = pkgs.neovim-nightly;
    vimAlias = true;
    vimdiffAlias = true;
    extraConfig = ''
      lua << EOF
      ${builtins.readFile ./init.lua}
      EOF
    '';
  };
}
