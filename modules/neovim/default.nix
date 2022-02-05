{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.custom.neovim;
in
{
  options = {
    custom.neovim.enable = mkEnableOption "Custom neovim setup";
    custom.neovim.package = mkOption {
      type = types.package;
      default = pkgs.neovim-unwrapped;
    };
    custom.neovim.colorscheme = mkOption {
      type = types.str;
      default = "default";
    };
  };

  config = mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      vimAlias = true;
      package = cfg.package;
      defaultEditor = true;
      configure =
        let
          settings = pkgs.vimUtils.buildVimPlugin { name = "settings"; src = builtins.path { path = ./settings; }; };
          telescope-zf-native = pkgs.vimUtils.buildVimPlugin {
            name = "telescope-zf-native.nvim";
            src = pkgs.fetchFromGitHub {
              owner = "natecraddock";
              repo = "telescope-zf-native.nvim";
              rev = "76ae732e4af79298cf3582ec98234ada9e466b58";
              sha256 = "sha256-acV3sXcVohjpOd9M2mf7EJ7jqGI+zj0BH9l0DJa14ak=";
            };
          };
          tempus-themes-vim = pkgs.vimUtils.buildVimPlugin {
            name = "tempus-themes-vim";
            src = pkgs.fetchFromGitLab {
              owner = "protesilaos";
              repo = "tempus-themes-vim";
              rev = "b720ee2d4c5588b5a27bb3544d3ded5ee1acab45";
              sha256 = "sha256-szM6S+qfhM3U+x9heooDFcMlOOAZj6Wp70WN92boWGQ=";
            };
          };
        in
        {
          customRC = ''
            colorscheme ${cfg.colorscheme}
          '';
          packages.myPlugins = with pkgs.vimPlugins; {
            start = [
              (nvim-treesitter.withPlugins (plugins: pkgs.tree-sitter.allGrammars))
              comment-nvim
              gruvbox-nvim
              lsp-colors-nvim
              lualine-nvim
              neogit
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
              vim-lastplace
              vim-nix
              vim-repeat
              vim-rsi
              vim-surround
              vim-vinegar
              zig-vim
            ] ++ [
              settings
              tempus-themes-vim
              telescope-zf-native
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
