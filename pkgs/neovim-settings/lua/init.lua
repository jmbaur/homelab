vim.g.mapleader = ","
vim.g.markdown_fenced_languages = {'bash=sh', 'python', 'typescript', 'go'}

require 'autopairs'
require 'comment'
require 'format'
require 'lsp'
require 'scope'
require 'sitter'
require 'snips'

local keymap = vim.api.nvim_set_keymap
local function inoremap(mapping, action)
    keymap("i", mapping, action, {noremap = true, silent = true})
end
local function nnoremap(mapping, action)
    keymap("n", mapping, action, {noremap = true, silent = true})
end

nnoremap("J", "mzJ`z")
nnoremap("Y", "y$")
nnoremap("<C-L>",
         ":nohlsearch<C-R>=has('diff')?'<Bar>diffupdate':''<CR><CR><C-L>")

inoremap("!", "!<c-g>u")
inoremap(",", ",<c-g>u")
inoremap(".", ".<c-g>u")
inoremap("?", "?<c-g>u")

vim.o.belloff = "all"
vim.o.clipboard = "unnamedplus"
vim.o.colorcolumn = "80"
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
vim.o.termguicolors = true
vim.o.undofile = true
vim.o.wrap = false

vim.cmd [[
colorscheme gruvbox
filetype plugin indent on
nnoremap <expr> j (v:count > 5 ? "m'" . v:count : "") . "j"
nnoremap <expr> k (v:count > 5 ? "m'" . v:count : "") . "k"
syntax enable
]]
