{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.custom.neovim;
in
{
  options = {
    custom.neovim.enable = mkEnableOption "Custom neovim setup";
  };

  config = mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      viAlias = true;
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
              lsp-colors-nvim
              nvim-autopairs
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
              vim-fugitive
              vim-lastplace
              vim-nix
              vim-repeat
              vim-rsi
              vim-surround
              vim-vinegar
              zig-vim
            ] ++ [
              (pkgs.vimUtils.buildVimPlugin {
                name = "acme.nvim";
                src = pkgs.fetchFromGitLab {
                  owner = "__tpb";
                  repo = "acme.nvim";
                  rev = "bee75f69289bb82e06263d8f2d403f183cf9c4d4";
                  sha256 = "sha256-fWpYtQ8gBFjrM4zLtomszkvMAGYyx/PdcRyWVyryKP0=";
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
      shfmt
      sumneko-lua-language-server
      tree-sitter
      zig
      zls
    ];

    environment.variables.SUMNEKO_ROOT_PATH = "${pkgs.sumneko-lua-language-server}";

  };
}
