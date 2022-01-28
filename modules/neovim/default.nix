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
      package = pkgs.symlinkJoin {
        name = "nvim-custom";
        paths = with pkgs; [
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
          neovim-unwrapped
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
      };
      defaultEditor = true;
      configure =
        let
          settings = pkgs.vimUtils.buildVimPlugin { name = "settings"; src = builtins.path { path = ./settings; }; };
          monokai-nvim = pkgs.vimUtils.buildVimPlugin {
            name = "monokai-nvim";
            src = pkgs.fetchFromGitHub {
              owner = "tanvirtin";
              repo = "monokai.nvim";
              rev = "a840804f5624f03bb6a4bd9358ac10700e2d9ab7";
              sha256 = "sha256-aFNhB6BONQsDwyhC/lwCYZdN6ex7TgagGpm+iwgGvXo=";
            };
          };
        in
        {
          packages.myPlugins = with pkgs.vimPlugins;
            {
              start = [
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
                vim-cue
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
              ] ++ [ monokai-nvim settings ];
              opt = [ editorconfig-vim ];
            };
        };
    };

    environment.variables.SUMNEKO_ROOT_PATH = "${pkgs.sumneko-lua-language-server}";
  };
}
