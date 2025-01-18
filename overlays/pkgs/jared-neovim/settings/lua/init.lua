vim.loader.enable()

vim.g.mapleader = vim.api.nvim_replace_termcodes("<Space>", true, true, true)

require("jmbaur.clipboard")
require("jmbaur.color")
require("jmbaur.compile")
require("jmbaur.filemanager")
require("jmbaur.git")
require("jmbaur.gzip")
require("jmbaur.launcher")
require("jmbaur.lsp")
require("jmbaur.project")
require("jmbaur.readline")
require("jmbaur.run")
require("jmbaur.rust")
require("jmbaur.sessions")
require("jmbaur.snippets")
require("jmbaur.terminal")
require("jmbaur.treesitter")
require("mini.trailspace").setup()
require("mini.bracketed").setup()
require("mini.surround").setup()
require("mini.basics").setup({
	mappings = { basic = false },
	autocommands = { relnum_in_visual_mode = true },
})

vim.opt.belloff = "all"
vim.opt.colorcolumn = "80"
vim.opt.foldmethod = "marker"
vim.opt.title = true

vim.opt.shell = "/bin/sh" -- should exist everywhere
vim.opt.showmatch = true

-- Undo what is done in mini.basics.
-- NOTE: This must come after setup for `mini.basics`.
vim.opt.cursorline = false
vim.opt.smartindent = false

-- Ensure that if nvim is used as MANPAGER, that we don't launch a nested nvim
-- when using man in nvim terminals.
vim.env.MANPAGER = nil
