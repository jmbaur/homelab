{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.neovim;

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
      bat
      black
      efm-langserver
      gcc
      git
      go
      goimports
      gopls
      luaformatter
      nixpkgs-fmt
      nodePackages.prettier
      nodePackages.typescript-language-server
      nodejs
      pyright
      python3
      ripgrep
      rnix-lsp
      rust-analyzer
      sumneko-lua-language-server
      tree-sitter
    ];

    environment.variables.SUMNEKO_ROOT_PATH = "${pkgs.sumneko-lua-language-server}";

  };
}
