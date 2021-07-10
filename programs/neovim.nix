{ config, pkgs, ... }: {
  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url =
        "https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz";
    }))
  ];
  environment.systemPackages = with pkgs; [
    gcc
    haskell-language-server
    nodePackages.typescript-language-server
    nodePackages.bash-language-server
    gopls
    rnix-lsp
    nixfmt
    pyright
    tree-sitter
    nodejs
  ];
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;
    configure = {
      packages.myPlugins = with pkgs.vimPlugins; {
        start = [
          vim-better-whitespace
          vim-lastplace
          vim-nix
          ayu-vim
          typescript-vim
          vim-commentary
          vim-fugitive
          vim-surround
          vim-repeat
          vim-rsi
          nvim-treesitter
          nvim-treesitter-textobjects
          nvim-lspconfig
          telescope-nvim
          popup-nvim
          plenary-nvim
          nvim-autopairs
        ];
        opt = [ ];
      };
      customRC = ''
        lua << EOF
        ${builtins.readFile ../configs/init.lua}
        EOF
      '';
    };
  };
}
