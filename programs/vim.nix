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
      typescript-vim
      vim-lsp
      vim-better-whitespace
      vim-eunuch
      vim-javascript
      vim-markdown
      vim-nix
      vim-protobuf
      vim-rsi
      vinegar
      zig-vim
    ];
    extraConfig = ''
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

      colorscheme solarized

      " Leader assignment must be above custom mappings for it to take effect.
      let mapleader=","
      let g:fzf_preview_window=[]
      let g:fzf_layout={'window':'enew'}

      inoremap ! !<c-g>u
      inoremap , ,<c-g>u
      inoremap . .<c-g>u
      inoremap ? ?<c-g>u
      nnoremap <expr> j (v:count > 5 ? "m'" . v:count : "") . "j"
      nnoremap <expr> k (v:count > 5 ? "m'" . v:count : "") . "k"
      nnoremap <leader>b :Buffers<CR>
      nnoremap <leader>f :Files<CR>
      nnoremap <leader>g :GFiles<CR>
      nnoremap <leader>r :Rg<CR>
      nnoremap J mzJ`z
      nnoremap N Nzzzv
      nnoremap n nzzzv

      if executable('gopls')
        au User lsp_setup call lsp#register_server({
        \ 'name': 'gopls',
        \ 'cmd': {server_info->['gopls']},
        \ 'allowlist': ['go'],
        \ })
      endif

      if executable('typescript-language-server')
        au User lsp_setup call lsp#register_server({
        \ 'name': 'typescript-language-server',
        \ 'cmd': {server_info->['typescript-language-server', '--stdio']},
        \ 'allowlist': ['typescript'],
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
        autocmd! BufWritePre *.rs,*.go call execute('LspDocumentFormatSync')

        " refer to doc to add more commands
      endfunction

      augroup lsp_install
        au!
        autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
      augroup END
    '';
  };
}
