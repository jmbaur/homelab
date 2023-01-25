vim.g.mapleader = " "

if #vim.api.nvim_list_uis() > 0 then
	local oil = require("oil")
	oil.setup()
	vim.keymap.set("n", "-", oil.open, { desc = "Open parent directory" })

	require("compile")
	require("gosee").setup()
	require("launcher")
	require("mini.trailspace").setup({})
	require("repl").setup()
	require("sitter")
	require("smartyank").setup({ highlight = { enabled = false }, osc52 = { silent = true } })
	require("snippet")

	if vim.g.boring == 0 then
		require("lsp")
	end

	vim.cmd.colorscheme("jared")
	vim.opt.belloff = "all"
	vim.opt.colorcolumn = "80"
	vim.opt.cursorline = true
	vim.opt.laststatus = 3
	vim.opt.number = true
	vim.opt.relativenumber = true
end

require("mini.comment").setup({})
require("nvim-surround").setup()

vim.opt.hidden = true
vim.opt.ignorecase = true
vim.opt.showmatch = true
vim.opt.smartcase = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.swapfile = false
vim.opt.undofile = true
vim.opt.wrap = false
