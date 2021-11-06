set background=dark
hi clear
if exists("syntax_on")
    syntax reset
endif
let g:colors_name = "jared"

hi clear Visual

hi ColorColumn                                  ctermbg=238
hi CursorLine       cterm=NONE
hi CursorLineNr     cterm=NONE	ctermfg=7
hi LineNr                       ctermfg=238
hi ShowMarksHL      cterm=bold  ctermfg=cyan	ctermbg=lightblue
hi SignColumn                                   ctermbg=NONE
hi Visual                       ctermfg=black   ctermbg=7
