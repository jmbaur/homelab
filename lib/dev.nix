{ config, pkgs, ... }:
let
  efm-langserver = import ../programs/efm-langserver { };
  proj = import ../programs/proj { };
in
{
  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz;
    }))
  ];

  environment.systemPackages = with pkgs; [
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
    neovim-nightly
    nixpkgs-fmt
    nodePackages.prettier
    nodePackages.typescript-language-server
    nodejs
    podman-compose
    pyright
    python3
    shellcheck
    shfmt
    skopeo
    zig
    zls
  ];

  virtualisation = {
    podman.enable = true;
    podman.dockerCompat = true;
    containers.enable = true;
    containers.containersConf.settings = {
      engine = { detach_keys = "ctrl-e,ctrl-q"; };
    };
  };
}
