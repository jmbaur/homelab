" vim: set ts=4 sts=4:
set background=dark
set clipboard=unnamedplus
set colorcolumn=80
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
" set undofile

color ron
syntax enable
filetype plugin indent on

if executable('haskell-language-server-wrapper')
        au User lsp_setup call lsp#register_server({
                                \ 'name': 'haskell-language-server-wrapper',
                                \ 'cmd': {server_info->['haskell-language-server-wrapper', '--lsp']},
                                \ 'allowlist': ['haskell'],
                                \ })
endif

if executable('gopls')
        au User lsp_setup call lsp#register_server({
                                \ 'name': 'gopls',
                                \ 'cmd': {server_info->['gopls']},
                                \ 'allowlist': ['go'],
                                \ })
endif

if executable('pyls')
        au User lsp_setup call lsp#register_server({
                                \ 'name': 'pyls',
                                \ 'cmd': {server_info->['pyls']},
                                \ 'allowlist': ['python'],
                                \ })
endif

function! s:on_lsp_buffer_enabled() abort
        setlocal omnifunc=lsp#complete
        setlocal signcolumn=yes
        if exists('+tagfunc') | setlocal tagfunc=lsp#tagfunc | endif
        nmap <buffer> gd <plug>(lsp-definition)
        nmap <buffer> gs <plug>(lsp-document-symbol-search)
        nmap <buffer> gS <plug>(lsp-workspace-symbol-search)
        nmap <buffer> gr <plug>(lsp-references)
        nmap <buffer> gi <plug>(lsp-implementation)
        nmap <buffer> gt <plug>(lsp-type-definition)
        nmap <buffer> <leader>rn <plug>(lsp-rename)
        nmap <buffer> [g <plug>(lsp-previous-diagnostic)
        nmap <buffer> ]g <plug>(lsp-next-diagnostic)
        nmap <buffer> K <plug>(lsp-hover)
        inoremap <buffer> <expr><c-f> lsp#scroll(+4)
        inoremap <buffer> <expr><c-d> lsp#scroll(-4)

        let g:lsp_format_sync_timeout = 1000
        autocmd! BufWritePre *.rs,*.go,*.hs,*.py call execute('LspDocumentFormatSync')

        " refer to doc to add more commands
endfunction

augroup lsp_install
        au!
        " call s:on_lsp_buffer_enabled only for languages that has the server registered.
        autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
augroup END

let g:markdown_fenced_languages=['bash=sh', 'python']
let g:fzf_preview_window=[]
let g:fzf_layout={'window':'enew'}
let mapleader=','

inoremap ! !<c-g>u
inoremap , ,<c-g>u
inoremap . .<c-g>u
inoremap ? ?<c-g>u
nmap <leader>b :Buffers<CR>
nmap <leader>f :Files<CR>
nmap <leader>g :GFiles<CR>
nmap <leader>r :Rg<CR>
nnoremap <expr> j (v:count > 5 ? "m'" . v:count : "") . "j"
nnoremap <expr> k (v:count > 5 ? "m'" . v:count : "") . "k"
nnoremap J mzJ`z
nnoremap N Nzzzv
nnoremap Y y$
nnoremap n nzzzv
