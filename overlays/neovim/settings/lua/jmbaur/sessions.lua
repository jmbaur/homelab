local sessions = require("mini.sessions")

sessions.setup({})

local augroup = vim.api.nvim_create_augroup("AutoSessions", {})

local autoread = function()
	if vim.fn.argc() == 0 and vim.fn.filereadable(vim.fn.getcwd() .. "/Session.vim") == 1 then
		sessions.read()
	end
end

vim.api.nvim_create_autocmd(
	"VimEnter",
	{ group = augroup, nested = true, once = true, callback = autoread, desc = "Autoread latest session" }
)
