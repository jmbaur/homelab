{ config, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # Neovim dependencies
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
  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url =
        "https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz";
    }))
  ];

  programs = {
    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      defaultEditor = true;
      configure = {
        packages.myPlugins = with pkgs.vimPlugins; {
          start = [
            vim-lastplace
            vim-nix
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
        customRC = builtins.readFile ../programs/init.vim;
      };
    };
  };
}
