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
        commit-hash = "0f574809bca4045f90d078e0f29f89f24b0563f0";
      in
      [
        (import (builtins.fetchTarball {
          url = "https://github.com/nix-community/neovim-nightly-overlay/archive/${commit-hash}.tar.gz";
          sha256 = "143k5igvazf9ml3pb2rshkwdzqyncpfsll4zfqnzrgx8nc5flghq";
        }))
      ];

    programs.neovim = {
      enable = true;
      vimAlias = true;
      defaultEditor = true;
      package = pkgs.neovim-nightly;
      configure = {
        packages.myPlugins = with pkgs.vimPlugins;
          let
            tree-sitter = (nvim-treesitter.withPlugins (plugins: pkgs.tree-sitter.allGrammars));
          in
          {
            start = [
              gruvbox-nvim
              nvim-autopairs
              nvim-colorizer-lua
              nvim-lspconfig
              snippets-nvim
              telescope-nvim
              tree-sitter
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
              (pkgs.vimUtils.buildVimPlugin {
                name = "tempus-themes-vim";
                src = pkgs.fetchFromGitLab {
                  owner = "protesilaos";
                  repo = "tempus-themes-vim";
                  rev = "b720ee2d4c5588b5a27bb3544d3ded5ee1acab45";
                  sha256 = "sha256-szM6S+qfhM3U+x9heooDFcMlOOAZj6Wp70WN92boWGQ=";
                };
              })
              (pkgs.vimUtils.buildVimPlugin {
                name = "vim-fugitive";
                src = pkgs.fetchFromGitHub {
                  owner = "tpope";
                  repo = "vim-fugitive";
                  rev = "4d29c1d6a0def18923b4762c8f85ca3ee5ae6c83";
                  sha256 = "1m8qw6pqgyvfnbph8xwpsvgwdyapsg2abxbpqvsjhcg6ylbxfx17";
                };
              })
              (pkgs.vimUtils.buildVimPlugin {
                name = "settings";
                src = builtins.path { path = ./settings; };
              })
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
      rust-analyzer
      sumneko-lua-language-server
      tree-sitter
    ];

    environment.variables.SUMNEKO_ROOT_PATH = "${pkgs.sumneko-lua-language-server}";

  };
}
