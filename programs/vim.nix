{ config, pkgs, ... }:
{
  programs.vim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      commentary
      fugitive
      fzf-vim
      haskell-vim
      nim-vim
      repeat
      rust-vim
      solarized
      surround
      tsuquyomi
      typescript-vim
      vim-better-whitespace
      vim-eunuch
      vim-go
      vim-javascript
      vim-markdown
      vim-nix
      vim-protobuf
      vim-rsi
      vinegar
      zig-vim
    ];
    extraConfig = ''
      colorscheme solarized
      let g:go_bin_path="/home/jared/go/bin"
      let mapleader = ","
      inoremap ! !<c-g>u
      inoremap , ,<c-g>u
      inoremap . .<c-g>u
      inoremap ? ?<c-g>u
      nnoremap <expr> j (v:count > 5 ? "m'" . v:count : "") . "j"
      nnoremap <expr> k (v:count > 5 ? "m'" . v:count : "") . "k"
      nnoremap <leader>b :Buffers!<CR>
      nnoremap <leader>f :Files!<CR>
      nnoremap <leader>g :GFiles!<CR>
      nnoremap <leader>r :Rg!<CR>
      nnoremap J mzJ`z
      nnoremap N Nzzzv
      nnoremap n nzzzv
      set background=dark
      set clipboard=unnamed
      set colorcolumn=80
      set expandtab
      set hidden
      set ignorecase
      set nocursorline
      set notermguicolors
      set nowrap
      set number
      set relativenumber
      set scrolloff=5
      set shiftwidth=2
      set showmatch
      set sidescrolloff=5
      set smartcase
      set softtabstop=2
      set splitbelow
      set splitright
      set tabstop=2
    '';
  };
}
