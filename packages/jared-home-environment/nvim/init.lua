local fzf_lua = require("fzf-lua")

vim.api.nvim_set_hl(0, "ExtraWhitespace", { bg = "red" })
vim.cmd.match("ExtraWhitespace /\\s\\+$/")
vim.api.nvim_create_autocmd({ "TextYankPost" }, {
	group = vim.api.nvim_create_augroup("TextYankPost", { clear = true }),
	pattern = "*",
	callback = function()
		vim.hl.on_yank({ higroup = "Visual", timeout = 300 })
	end,
})

vim.api.nvim_create_autocmd({ "TermOpen" }, {
	group = vim.api.nvim_create_augroup("TermOpen", { clear = true }),
	callback = function()
		local ns_id = vim.api.nvim_create_namespace("terminal")
		vim.api.nvim_win_set_hl_ns(vim.api.nvim_get_current_win(), ns_id)
		vim.api.nvim_set_hl(ns_id, "ExtraWhitespace", {})

		vim.opt_local.spell = false
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
		vim.opt_local.signcolumn = "no"
		vim.cmd.startinsert()
	end,
})

vim.api.nvim_create_autocmd({ "ColorScheme" }, {
	group = vim.api.nvim_create_augroup("ColorScheme", { clear = true }),
	callback = function()
		vim.api.nvim_set_hl(0, "Normal", {})
	end,
})

function setup_fzf(background)
	fzf_lua.setup({
		fzf_args = string.format("--color=%s", background or "dark"),
		defaults = { file_icons = false },
		files = { previewer = false },
		winopts = {
			split = "botright 15new",
			border = "single",
			preview = {
				hidden = "hidden",
				border = "border",
				title = false,
				layout = "horizontal",
				horizontal = "right:50%",
			},
		},
	})
end

-- Neovim does some detection of the terminal background color prior to setting
-- the "background" option (unless of course we set it explicitly ourselves).
-- So in order to ensure fzf-lua has a correct initial configuration according
-- to what we want, even if the "background" option hasn't been set yet, we can
-- do the initial configuration here and then perform the configuration again
-- once the "background" option is set.
setup_fzf()

-- Will be called once per startup. This is the only way we can obtain the
-- correct auto-detected background set by neovim.
vim.api.nvim_create_autocmd({ "OptionSet" }, {
	pattern = { "background" },
	callback = function(opts)
		if opts.match == "background" then
			setup_fzf(vim.opt.background:get())
		end
	end,
})

vim.g.clipboard = "osc52"
vim.g.dispatch_no_tmux_make = 1
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.mapleader = vim.api.nvim_replace_termcodes("<Space>", true, true, true)

vim.opt.autoread = true
vim.opt.clipboard = "unnamedplus"
vim.opt.colorcolumn = tostring(80)
vim.opt.completeopt = table.concat({ "popup", "menuone", "noinsert", "noselect", "fuzzy" }, ",")
vim.opt.exrc = true
vim.opt.hidden = true
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.laststatus = 2
vim.opt.number = true
vim.opt.ruler = true
vim.opt.shortmess:remove({ "S" })
vim.opt.showcmd = true
vim.opt.showmatch = true
vim.opt.smartcase = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.termguicolors = vim.regex("linux\\|vt220\\|dumb"):match_str(vim.env.TERM) == nil
vim.opt.title = true
vim.opt.wildoptions = table.concat({ "pum", "tagfile" }, ",")
vim.opt.wrap = false

vim.cmd.colorscheme(vim.opt.termguicolors:get() and "lunaperche" or "default")

-- TODO(jared): use vim.snippet
vim.cmd.iabbrev("todo:", "TODO(jared):")

fzf_lua.register_ui_select()

vim.keymap.set("n", "<Leader>?", fzf_lua.helptags, { desc = "Find help tags" })
vim.keymap.set("n", "<Leader>_", fzf_lua.registers, { desc = "Find registers" })
vim.keymap.set("n", "<Leader>b", fzf_lua.buffers, { desc = "Find buffers" })
vim.keymap.set("n", "<Leader>c", fzf_lua.resume, { desc = "Resume picker" })
vim.keymap.set("n", "<Leader>f", fzf_lua.files, { desc = "Find files" })
vim.keymap.set("n", "<Leader>g", fzf_lua.live_grep, { desc = "Find regexp pattern" })
vim.keymap.set("n", "<Leader>h", fzf_lua.command_history, { desc = "Find Ex-mode history" })

require("nvim-treesitter.configs").setup({
	indent = { enable = true },
	highlight = {
		enable = true,
		additional_vim_regex_highlighting = false,
	},
})
