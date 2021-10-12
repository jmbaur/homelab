{ config, pkgs, ... }:
let
  unstable = import ./unstable.nix { };
  efm-langserver = import ../programs/efm-langserver { };
  proj = import ../programs/proj { };
in
{
  environment.systemPackages =
    (with pkgs;
    [
      black
      buildah
      ctags
      delta
      efm-langserver
      gnumake
      go
      goimports
      gopls
      luaformatter
      mob
      nixpkgs-fmt
      nodePackages.prettier
      nodePackages.typescript-language-server
      nodePackages.yaml-language-server
      nodejs
      podman-compose
      pyright
      python3
      rust-analyzer
      rustfmt
      shellcheck
      shfmt
      skopeo
    ])
    ++
    (with unstable; [
      neovim
      zig
      zls
    ])
  ;

  virtualisation = {
    podman.enable = true;
    podman.dockerCompat = true;
    containers.enable = true;
    containers.containersConf.settings = {
      engine = { detach_keys = "ctrl-e,ctrl-q"; };
    };
  };
}
