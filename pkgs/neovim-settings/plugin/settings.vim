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
set tabstop=4
set undofile

inoremap ! !<c-g>u
inoremap , ,<c-g>u
inoremap . .<c-g>u
inoremap ? ?<c-g>u
nnoremap <expr> j (v:count > 5 ? "m'" . v:count : "") . "j"
nnoremap <expr> k (v:count > 5 ? "m'" . v:count : "") . "k"
nnoremap J mzJ`z
nnoremap Y y$

if maparg('<C-L>', 'n') ==# ''
		nnoremap <silent> <C-L> :nohlsearch<C-R>=has('diff')?'<Bar>diffupdate':''<CR><CR><C-L>
endif

let g:markdown_fenced_languages=['bash=sh', 'python', 'typescript', 'go']
let mapleader=','

filetype plugin indent on
syntax enable

lua require('init')
