lua require('init')

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

let mapleader=','

filetype plugin indent on
syntax enable

highlight WinSeparator ctermfg=None guifg=None
