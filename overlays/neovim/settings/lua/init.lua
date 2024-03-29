vim.loader.enable()

vim.g.mapleader = " "

-- If not using nvim's remote UI
if #vim.api.nvim_list_uis() > 0 then
	local launcher = require("jmbaur.launcher")
	launcher.setup()

	require("diffview").setup({ use_icons = false })
	require("gitsigns").setup({ signcolumn = false })
	require("gosee").setup()
	require("jmbaur.clipboard")
	require("jmbaur.compile")
	require("jmbaur.filemanager")
	require("jmbaur.lsp").setup({ launcher = launcher })
	require("jmbaur.repl")
	require("jmbaur.run").setup()
	require("jmbaur.snippets")
	require("jmbaur.statusline")
	require("jmbaur.treesitter")
	require("jmbaur.sessions")
	require("mini.tabline").setup({ show_icons = false, set_vim_settings = false })
	require("mini.trailspace").setup({})

	vim.opt.belloff = "all"
	vim.opt.colorcolumn = "80"
	vim.opt.cursorline = false
	vim.opt.foldmethod = "marker"
	vim.opt.laststatus = 2
	vim.opt.list = true
	vim.opt.listchars = { eol = "↴", tab = "  ⇥", nbsp = "·" }
	vim.opt.number = true
	vim.opt.relativenumber = true
	vim.opt.shell = "/run/current-system/sw/bin/bash"
	vim.opt.splitkeep = "screen"
	vim.opt.termguicolors = true
	vim.opt.title = true
end

require("mini.bracketed").setup({})
require("mini.comment").setup({
	ignore_blank_line = true,
	start_of_line = true,
})
require("mini.surround").setup({})

vim.opt.hidden = true
vim.opt.ignorecase = true
vim.opt.showmatch = true
vim.opt.smartcase = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.swapfile = false
vim.opt.undofile = true
vim.opt.wrap = false
