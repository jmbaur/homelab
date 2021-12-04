self: super: {
  neovim = super.neovim.override {
    vimAlias = true;
    configure = {
      packages.plugins = with super.vimPlugins; {
        start = [
          (nvim-treesitter.withPlugins (plugins: super.tree-sitter.allGrammars))
          (super.vimUtils.buildVimPlugin { name = "settings"; src = builtins.path { path = ./neovim; }; })
          comment-nvim
          lsp-colors-nvim
          nvim-autopairs
          nvim-lspconfig
          snippets-nvim
          telescope-nvim
          toggleterm-nvim
          tokyonight-nvim
          trouble-nvim
          typescript-vim
          vim-better-whitespace
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
}
