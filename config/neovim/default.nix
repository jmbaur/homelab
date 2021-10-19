{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.neovim;

  efm-langserver = import ../../pkgs/efm-langserver { };

in
{
  options = {
    custom.neovim = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable custom neovim setup.
        '';
      };
    };
  };

  config = mkIf cfg.enable {

    nixpkgs.overlays =
      let
        commit-hash = "1dd99a6c91b4a6909e66d0ee69b3f31995f38851";
      in
      [
        (import (builtins.fetchTarball {
          url = "https://github.com/nix-community/neovim-nightly-overlay/archive/${commit-hash}.tar.gz";
          sha256 = "1z8gx1cqd18s8zgqksjbyinwgcbndg2r6wv59c4qs24rbgcsvny9";
        }))
      ];

    programs.neovim = {
      enable = true;
      vimAlias = true;
      defaultEditor = true;
      package = pkgs.neovim-nightly;
      configure = {
        packages.myPlugins = with pkgs.vimPlugins; {
          start = [
            (nvim-treesitter.withPlugins (plugins: pkgs.tree-sitter.allGrammars))
            gruvbox-nvim
            nvim-autopairs
            nvim-lspconfig
            snippets-nvim
            telescope-nvim
            trouble-nvim
            typescript-vim
            vim-better-whitespace
            vim-commentary
            vim-dadbod
            vim-easy-align
            vim-eunuch
            vim-lastplace
            vim-nix
            vim-repeat
            vim-rsi
            vim-surround
            vim-vinegar
            zig-vim
          ] ++ [
            (
              pkgs.vimUtils.buildVimPlugin {
                name = "vim-fugitive";
                src = pkgs.fetchFromGitHub {
                  owner = "tpope";
                  repo = "vim-fugitive";
                  rev = "4d29c1d6a0def18923b4762c8f85ca3ee5ae6c83";
                  sha256 = "1m8qw6pqgyvfnbph8xwpsvgwdyapsg2abxbpqvsjhcg6ylbxfx17";
                };
              }
            )
            (
              pkgs.vimUtils.buildVimPlugin {
                name = "stabilize-nvim";
                src = pkgs.fetchFromGitHub {
                  owner = "luukvbaal";
                  repo = "stabilize.nvim";
                  rev = "0b9d82a6aaf2ccb8e7c07f99ba463505de8033e8";
                  sha256 = "101bq44wxcqy07lyihwiz1b48rzdb5wgjkvjw6nlzqk9034zqn2p";
                };
              }
            )
            (
              pkgs.vimUtils.buildVimPlugin {
                name = "settings";
                src = builtins.path { path = ./settings; };
              }
            )
          ];
          opt = [ editorconfig-vim ];
        };
      };
    };

    environment.systemPackages = with pkgs; [
      black
      efm-langserver
      gcc
      go
      gopls
      luaformatter
      nixpkgs-fmt
      pyright
      python3
      rnix-lsp
      tree-sitter
    ];

  };
}
