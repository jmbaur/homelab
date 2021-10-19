colorscheme gruvbox
filetype plugin indent on

set background=dark
set clipboard=unnamedplus
set colorcolumn=80
set expandtab
set hidden
set ignorecase
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
syntax enable

let g:markdown_fenced_languages=['bash=sh', 'python']
let mapleader=','

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

lua require('init')
