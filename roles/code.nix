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
    # programming utilities
    direnv
    nix-direnv
    fd
    gh
    tig
    ripgrep
    skopeo
    buildah
    podman-compose
  ];

  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url =
        "https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz";
    }))
  ];

  environment.pathsToLink = [ "/share/nix-direnv" ];

  # So GC doesn't clean up nix shells
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
  '';

  programs = {
    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      defaultEditor = true;
      configure = {
        packages.myPlugins = with pkgs.vimPlugins; {
          start = [
            awesome-vim-colorschemes
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
        customRC = builtins.readFile ../programs/init.vim;
      };
    };
  };

  virtualisation = {
    podman.enable = true;
    podman.dockerCompat = true;
    containers.enable = true;
    containers.containersConf.settings = {
      engine = { detach_keys = "ctrl-e,ctrl-q"; };
    };
  };

}
