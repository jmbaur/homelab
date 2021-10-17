{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.custom.vim;

  my-vim = import ./my-vim { };

  vim = pkgs.vim_configurable.customize {
    name = "vim";
    vimrcConfig.packages.myplugins =
      with pkgs.vimPlugins; {
        start = [
          auto-pairs
          fzf-vim
          fzfWrapper
          haskell-vim
          nim-vim
          typescript-vim
          vim-better-whitespace
          vim-commentary
          vim-dadbod
          vim-easy-align
          vim-eunuch
          vim-fugitive
          vim-lastplace
          vim-lsp
          vim-markdown
          vim-nix
          vim-repeat
          vim-rsi
          vim-sensible
          vim-shellcheck
          vim-surround
          vim-vinegar
          xterm-color-table
          zig-vim
        ] ++ [
          my-vim
        ];
        opt = [
          editorconfig-vim
        ];
      };
  };
in
{
  options = {
    custom.vim = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable custom vim setup.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    environment.variables.EDITOR = "vim";
    environment.systemPackages = with pkgs; [
      # Haskell
      ghc
      haskell-language-server

      # Go
      go
      gopls

      # Nix
      nixpkgs-fmt
      rnix-lsp

      # Nodejs ecosystem
      nodePackages.bash-language-server
      nodePackages.typescript-language-server
      nodePackages.yaml-language-server
      nodejs

      # Python
      black
      python3
      python38Packages.python-language-server

      # Bash
      shellcheck

      # Zig
      zig
      zls
    ] ++ [ vim ];
  };
}
