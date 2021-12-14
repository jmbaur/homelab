set background=dark
hi clear
if exists("syntax_on")
    syntax reset
endif
let g:colors_name = "jared"

hi clear Visual

hi ColorColumn                                  ctermbg=238             guibg=gray
hi CursorLine       cterm=NONE
hi CursorLineNr     cterm=NONE	ctermfg=7
hi LineNr                       ctermfg=238 guifg=gray
hi Pmenu                                        ctermbg=245             guibg=gray
hi ShowMarksHL      cterm=bold  ctermfg=cyan	ctermbg=lightblue
hi SignColumn                                   ctermbg=NONE            guibg=NONE
hi Visual                       ctermfg=black   ctermbg=7               guibg=gray
