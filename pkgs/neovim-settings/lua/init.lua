require 'autopairs'
require 'color'
require 'comment'
require 'lsp'
require 'scope'
require 'sitter'
require 'snips'
require 'term'
require 'troublings'

vim.g.markdown_fenced_languages = {'bash=sh', 'python', 'typescript', 'go'}

vim.o.belloff = "all"
vim.o.clipboard = "unnamedplus"
vim.o.colorcolumn = 80
vim.o.cursorline = false
vim.o.expandtab = false
vim.o.hidden = true
vim.o.ignorecase = true
vim.o.laststatus = 3
vim.o.mouse = "a"
vim.o.number = true
vim.o.relativenumber = true
vim.o.shiftwidth = 4
vim.o.showmatch = true
vim.o.smartcase = true
vim.o.softtabstop = 4
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.statusline = "%<%f %h%m%r%{FugitiveStatusline()}%=%-14.(%l,%c%V%) %P"
vim.o.swapfile = false
vim.o.tabstop = 4
vim.o.undofile = true
vim.o.wrap = false
