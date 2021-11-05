set background=dark
set belloff=all
set clipboard=unnamedplus
set colorcolumn=80
set expandtab
set hidden
set ignorecase
set mouse=a
set nocursorline
set noswapfile
set nowrap
set number
set relativenumber
set showmatch
set smartcase
set splitbelow
set splitright
set statusline=%<%f\ %h%m%r%{FugitiveStatusline()}%=%-14.(%l,%c%V%)\ %P
set termguicolors
set undofile

if has('gui_running')
        set guioptions=-L
        set guioptions=-T
        set guioptions=-m
        set guioptions=-r
        set guifont=monospace\ 14
endif

inoremap ! !<c-g>u
inoremap , ,<c-g>u
inoremap . .<c-g>u
inoremap ? ?<c-g>u
nnoremap <expr> j (v:count > 5 ? "m'" . v:count : "") . "j"
nnoremap <expr> k (v:count > 5 ? "m'" . v:count : "") . "k"
nnoremap J mzJ`z
nnoremap N Nzzzv
nnoremap Y y$
nnoremap n nzzzv

if maparg('<C-L>', 'n') ==# ''
        nnoremap <silent> <C-L> :nohlsearch<C-R>=has('diff')?'<Bar>diffupdate':''<CR><CR><C-L>
endif

let g:markdown_fenced_languages=['bash=sh', 'python']
let mapleader=','

filetype plugin indent on
syntax enable

color industry

lua require('init')
