{ pkgs, config, ... }:
let
  kitty-to-colorbuddy = pkgs.writeShellScriptBin "kitty-to-colorbuddy" ''
    grep ^color $1 | sed -r "s/(color[0-9]+).*(\#[a-z0-9]{6}$)/Color.new('\1', '\2')/"
  '';
  efm-langserver = pkgs.callPackage ../efm-ls.nix { };
  unstable = import ../../misc/unstable.nix { config = config.nixpkgs.config; };
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

  environment.systemPackages = with pkgs; [
    clang
    efm-langserver
    go
    goimports
    gopls
    haskell-language-server
    kitty-to-colorbuddy
    luaformatter
    neovim-nightly
    nixpkgs-fmt
    nodejs
    pyright
    python3
    rnix-lsp
    shellcheck
    shfmt
    stylish-haskell
    sumneko-lua-language-server
    tree-sitter
    yaml-language-server
  ] ++ (
    with pkgs.nodePackages; [
      bash-language-server
      prettier
      typescript-language-server
    ]
  ) ++ (
    with unstable; [
      zig
      zls
    ]
  );
  home-manager.users.jared.programs.neovim = {
    enable = true;
    package = pkgs.neovim-nightly;
    vimAlias = true;
    vimdiffAlias = true;
    extraConfig = ''
      lua << EOF
      -- Used in ./init.lua
      Sumneko_bin = "${pkgs.sumneko-lua-language-server}/bin/lua-language-server"
      Sumneko_main = "${pkgs.sumneko-lua-language-server}/extras/main.lua"
      ${builtins.readFile ./init.lua}
      EOF
    '';
  };
}
