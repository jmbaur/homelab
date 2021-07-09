{ config, pkgs, ... }:
let
  home-manager = builtins.fetchGit {
    url = "https://github.com/nix-community/home-manager.git";
    rev = "35a24648d155843a4d162de98c17b1afd5db51e4";
    ref = "release-21.05";
  };
in { imports = [ (import "${home-manager}/nixos") ]; }
