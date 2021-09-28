{ config, pkgs, ... }:
let
  fugitive = pkgs.vimUtils.buildVimPlugin { name = "vim-fugitive"; src = builtins.fetchGit { url = "https://github.com/tpope/vim-fugitive"; ref = "master"; }; };
in
{
  programs.neovim = {
    enable = true;
    # package = pkgs.neovim-nightly;
    vimAlias = true;
    vimdiffAlias = true;
    plugins = with pkgs.vimPlugins; [
      NeoSolarized
      commentary
      # lsp-colors-nvim
      # nvim-autopairs
      # nvim-dap
      # nvim-lspconfig
      # nvim-treesitter
      # plenary-nvim
      repeat
      # snippets-nvim
      surround
      # telescope-nvim
      # typescript-vim
      # vim-better-whitespace
      # vim-nix
      vim-rsi
      zig-vim
    ] ++ [
      fugitive
    ];
    extraConfig = ''
      lua << EOF
      -- Used in ./init.lua
      Sumneko_bin = "${pkgs.sumneko-lua-language-server}/bin/lua-language-server"
      Sumneko_main = "${pkgs.sumneko-lua-language-server}/extras/main.lua"
      ${builtins.readFile ./init.lua}
      EOF
    '';

  };
}
