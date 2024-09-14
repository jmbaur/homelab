vim.loader.enable()

vim.cmd.source("@langSupportLua@")

vim.g.mapleader = " "

-- If not using nvim's remote UI
if #vim.api.nvim_list_uis() > 0 then
	vim.cmd.colorscheme("lunaperche")

	-- Ensure terminal doesn't have miscolored padding on sides
	local mini_misc = require("mini.misc")
	mini_misc.setup_termbg_sync()

	local launcher = require("jmbaur.launcher")
	launcher.setup()

	require("jmbaur.clipboard")
	require("jmbaur.compile")
	require("jmbaur.filemanager")
	require("jmbaur.git")
	require("jmbaur.lsp").setup({ launcher = launcher })
	require("jmbaur.readline")
	require("jmbaur.run").setup()
	require("jmbaur.sessions")
	require("jmbaur.snippets")
	require("jmbaur.treesitter")
	require("mini.trailspace").setup({})

	vim.opt.belloff = "all"
	vim.opt.colorcolumn = "80"
	vim.opt.cursorline = false
	vim.opt.foldmethod = "marker"
	vim.opt.laststatus = 2
	vim.opt.list = false
	vim.opt.listchars = { tab = "  \xe2\x87\xa5", trail = "\xc2\xb7", nbsp = "\xc2\xb7" }
	vim.opt.number = true
	vim.opt.relativenumber = true
	vim.opt.shell = "/run/current-system/sw/bin/bash"
	vim.opt.splitkeep = "screen"
	vim.opt.title = true
end

require("mini.bracketed").setup({})
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
