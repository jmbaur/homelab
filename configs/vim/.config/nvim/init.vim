let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.
			  \data_dir.'/autoload/plug.vim '.
			  \'--create-dirs '.
			  \'https://raw.githubusercontent.com/'.
			  \'junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin()

Plug 'LnL7/vim-nix'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'junegunn/vim-easy-align'
Plug 'leafgarland/typescript-vim'
Plug 'neovim/nvim-lspconfig'
Plug 'norcalli/snippets.nvim'
Plug 'ntpeters/vim-better-whitespace'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-markdown'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-rsi'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-vinegar'
Plug 'ziglang/zig.vim'

call plug#end()

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set background=dark
set clipboard=unnamedplus
set colorcolumn=80
set completeopt-=preview " Prevent LSP preview window from opening on omnifunc
set nocursorline
set hidden
set ignorecase
set noswapfile
set notermguicolors
set nowrap
set number
set relativenumber
set scrolloff=5
set showmatch
set sidescrolloff=5
set smartcase
set splitbelow
set splitright
set statusline=%<%f\ %h%m%r%{FugitiveStatusline()}%=%-14.(%l,%c%V%)\ %P
set undofile

colorscheme jared

syntax enable
filetype plugin indent on

let g:markdown_fenced_languages=['bash=sh']
let g:fzf_preview_window=[]
let g:fzf_layout={'window':'enew'}
let mapleader=','

inoremap ! !<c-g>u
inoremap , ,<c-g>u
inoremap . .<c-g>u
inoremap <c-j> <cmd>lua return require"snippets".advance_snippet(-1)<CR>
inoremap <c-k> <cmd>lua return require"snippets".expand_or_advance(1)<CR>
inoremap ? ?<c-g>u
nmap <leader>b :Buffers<CR>
nmap <leader>f :Files<CR>
nmap <leader>g :GFiles<CR>
nmap <leader>r :Rg<CR>
nnoremap <expr> j (v:count > 5 ? "m'" . v:count : "") . "j"
nnoremap <expr> k (v:count > 5 ? "m'" . v:count : "") . "k"
nnoremap J mzJ`z
nnoremap N Nzzzv
nnoremap n nzzzv

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
luafile ~/.config/nvim/lua/init.lua
