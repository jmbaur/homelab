{ boring ? false, neovim-unwrapped, vimPlugins, wrapNeovim, ... }:
let
  configure = {
    customRC = ''
      lua vim.g.boring = ${if boring then "1" else "0"}
    '';
    packages.plugins = with vimPlugins; {
      start = [
        editorconfig-nvim
        gitsigns-nvim
        gosee-nvim
        jmbaur-settings
        mini-nvim
        null-ls-nvim
        nvim-colorizer-lua
        nvim-lspconfig
        nvim-surround
        nvim-treesitter-refactor
        nvim-treesitter-textobjects
        nvim-treesitter.withAllGrammars
        playground
        smartyank-nvim
        snippets-nvim
        telescope-nvim
        telescope-ui-select-nvim
        vim-dirvish
        vim-dispatch
        vim-eunuch
        vim-fugitive
        vim-nix
        vim-repeat
        vim-rsi
        vim-unimpaired
      ];
    };
  };
in
wrapNeovim neovim-unwrapped {
  inherit configure;
  vimAlias = true;
}
