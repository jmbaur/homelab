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
      vimAlias = true;
      defaultEditor = true;
      configure = {
        packages.myPlugins = with pkgs.vimPlugins;
          {
            start = [
              (nvim-treesitter.withPlugins (plugins: pkgs.tree-sitter.allGrammars))
              (pkgs.vimUtils.buildVimPlugin { name = "settings"; src = builtins.path { path = ./settings; }; })
              comment-nvim
              lsp-colors-nvim
              nvim-autopairs
              nvim-lspconfig
              snippets-nvim
              telescope-nvim
              toggleterm-nvim
              trouble-nvim
              typescript-vim
              vim-better-whitespace
              vim-clang-format
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
            ];
            opt = [ editorconfig-vim ];
          };
      };
    };

    environment.systemPackages = with pkgs; [
      bat
      black
      cargo
      clang-tools
      efm-langserver
      git
      go
      goimports
      gopls
      luaformatter
      neovide
      nixpkgs-fmt
      nodePackages.typescript
      nodePackages.typescript-language-server
      nodejs
      pyright
      python3
      ripgrep
      rust-analyzer
      rustfmt
      shfmt
      sumneko-lua-language-server
      tree-sitter
      zig
      zls
    ];

    environment.variables.SUMNEKO_ROOT_PATH = "${pkgs.sumneko-lua-language-server}";

  };
}
