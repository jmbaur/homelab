vim.loader.enable()

vim.g.mapleader = vim.api.nvim_replace_termcodes("<Space>", true, true, true)

-- If not using nvim's remote UI, this means we are using neovim in such a way
-- that we can take advantage of neovim front-end related features.
if #vim.api.nvim_list_uis() > 0 then
	require("jmbaur.clipboard")
	require("jmbaur.compile")
	require("jmbaur.filemanager")
	require("jmbaur.git")
	require("jmbaur.gzip")
	require("jmbaur.launcher")
	require("jmbaur.lsp")
	require("jmbaur.notify")
	require("jmbaur.project")
	require("jmbaur.readline")
	require("jmbaur.run")
	require("jmbaur.sessions")
	require("jmbaur.snippets")
	require("jmbaur.terminal")
	require("jmbaur.treesitter")
	require("mini.trailspace").setup()

	vim.opt.belloff = "all"
	vim.opt.colorcolumn = "80"
	vim.opt.foldmethod = "marker"
	vim.opt.title = true
end

require("mini.bracketed").setup()
require("mini.surround").setup()
require("mini.basics").setup({
	mappings = { basic = false },
	autocommands = { relnum_in_visual_mode = true },
})

vim.opt.shell = "/bin/sh" -- should exist everywhere
vim.opt.showmatch = true
vim.opt.cursorline = false -- undo what is done in mini.basics
