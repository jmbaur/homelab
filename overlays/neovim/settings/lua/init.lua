vim.loader.enable()

vim.g.mapleader = " "

if #vim.api.nvim_list_uis() > 0 then
	local launcher = require("launcher")
	launcher.setup()

	require("diffview").setup({ use_icons = false })
	require("compile")
	require("filemanager")
	require("gitsigns").setup({ signcolumn = false })
	require("gosee").setup()
	require("lsp").setup({ launcher = launcher })
	require("mini.tabline").setup({ show_icons = false, set_vim_settings = false })
	require("mini.trailspace").setup({})
	require("run").setup()
	require("sitter")
	require("clipboard")
	require("snippet")
	require("statusline")

	vim.opt.termguicolors = true
	vim.opt.belloff = "all"
	vim.opt.colorcolumn = "80"
	vim.opt.cursorline = false
	vim.opt.laststatus = 2
	vim.opt.number = true
	vim.opt.relativenumber = true
	vim.opt.splitkeep = "screen"
end

require("mini.bracketed").setup({})
require("mini.comment").setup({
	ignore_blank_line = true,
	start_of_line = true,
})
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
