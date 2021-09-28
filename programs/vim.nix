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
      tagbar
      tsuquyomi
      typescript-vim
      vim-better-whitespace
      vim-eunuch
      vim-go
      vim-gutentags
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
      let g:gutentags_file_list_command="${pkgs.ripgrep}/bin/rg --files"
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
      nnoremap <leader>t :TagbarToggle<CR>
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
      set statusline=%<%f\ %h%m%r%{FugitiveStatusline()}%=%-14.(%l,%c%V%)\ %P
      set tabstop=2

      let g:tagbar_type_typescript = {
        \ "ctagstype": "typescript",
        \ "kinds": [
          \ "c:classes",
          \ "n:modules",
          \ "f:functions",
          \ "v:variables",
          \ "v:varlambdas",
          \ "m:members",
          \ "i:interfaces",
          \ "e:enums",
        \ ]
      \ }

      let g:tagbar_type_zig = {
        \ "ctagstype": "zig",
        \ "kinds" : [
           \ "f:functions",
           \ "s:structs",
           \ "e:enums",
           \ "u:unions",
           \ "E:errors",
         \ ]
      \ }

      let g:tagbar_type_go = {
        \ "ctagstype": "go",
        \ "kinds" : [
          \ "p:package",
          \ "f:function",
          \ "v:variables",
          \ "t:type",
          \ "c:const"
        \ ]
      \ }
    '';
  };
}
