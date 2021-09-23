{ pkgs, configs, ... }:
let
  kitty-to-colorbuddy = pkgs.writeShellScriptBin "kitty-to-colorbuddy" ''
    grep ^color $1 | sed -r "s/(color[0-9]+).*(\#[a-z0-9]{6}$)/Color.new('\1', '\2')/"
  '';
  home-manager = import ./home-manager.nix { ref = "release-21.05"; };
in {
  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url =
        "https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz";
    }))
  ];
  environment.systemPackages = [ kitty-to-colorbuddy pkgs.neovim-nightly ];
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
