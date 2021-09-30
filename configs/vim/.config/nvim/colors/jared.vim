set background=dark
hi clear
if exists("syntax_on")
  syntax reset
endif
let g:colors_name = "jared"

hi clear Visual

hi ColorColumn		ctermbg=8
hi CursorLine		cterm=NONE
hi CursorLineNr		cterm=NONE	ctermfg=7
hi LineNr		ctermfg=8
hi ShowMarksHL		cterm=bold	ctermfg=cyan	ctermbg=lightblue
hi SignColumn		ctermbg=NONE
hi Visual		term=reverse	cterm=reverse
