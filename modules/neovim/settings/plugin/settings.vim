set belloff=all
set clipboard=unnamedplus
set colorcolumn=80
set hidden
set ignorecase
set mouse=a
set nocursorline
set noexpandtab
set noswapfile
set nowrap
set number
set relativenumber
set shiftwidth=4
set showmatch
set smartcase
set softtabstop=4
set splitbelow
set splitright
set statusline=%<%f\ %h%m%r%{FugitiveStatusline()}%=%-14.(%l,%c%V%)\ %P
set tabstop=4
set termguicolors
set undofile

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

let g:clang_format#auto_format=1

let g:markdown_fenced_languages=['bash=sh', 'python', 'typescript', 'go']
let mapleader=','

autocmd FileType markdown setlocal spell complete+=kspell
autocmd FileType gitcommit setlocal spell complete+=kspell

filetype plugin indent on
syntax enable

lua require('init')
