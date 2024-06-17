vim.loader.enable()

vim.cmd.source("@langSupportLua@")

vim.g.mapleader = " "

-- If not using nvim's remote UI
if #vim.api.nvim_list_uis() > 0 then
	vim.cmd.colorscheme("lunaperche")

	local launcher = require("jmbaur.launcher")
	launcher.setup()

	require("jmbaur.clipboard")
	require("jmbaur.compile")
	require("jmbaur.filemanager")
	require("jmbaur.lsp").setup({ launcher = launcher })
	require("jmbaur.run").setup()
	require("jmbaur.sessions")
	require("jmbaur.snippets")
	require("jmbaur.statusline")
	require("jmbaur.treesitter")
	require("mini.diff").setup({})
	require("mini.git").setup({})
	require("mini.tabline").setup({ show_icons = false, set_vim_settings = false })
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

	-- Use BufNew since it is only called once on the creation of a new buffer,
	-- unlike BufEnter, which is called everytime the buffer is entered
	vim.api.nvim_create_autocmd({ "BufNew" }, {
		desc = "Setup MiniDiff",
		callback = function(args)
			if not vim.api.nvim_buf_is_valid(args.buf) then return nil end
			vim.b[args.buf or 0].minidiff_disable = true -- disabled by default, but toggleable

			vim.api.nvim_buf_create_user_command(args.buf, "Diff", function()
				vim.b[args.buf or 0].minidiff_disable = false
				MiniDiff.toggle(args.buf)
			end, { desc = "Toggle MiniDiff" })
		end
	})
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
