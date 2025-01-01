local telescope = require("telescope")
local telescope_builtin = require("telescope.builtin")
local telescope_themes = require("telescope.themes")

telescope.setup({
	-- TODO(jared): Might be a better way to set default theme in future,
	-- see https://github.com/nvim-telescope/telescope.nvim/issues/848.
	defaults = vim.tbl_deep_extend(
		"force",
		telescope_themes.get_dropdown(),
		{ color_devicons = false, file_ignore_patterns = { "^.git/" } }
	),
	pickers = { find_files = { hidden = true, previewer = false } },
})

telescope.load_extension("ui-select")
telescope.load_extension("zf-native")

vim.keymap.set("n", "<Leader>?", telescope_builtin.help_tags, { desc = "Find help tags" })
vim.keymap.set("n", "<Leader>_", telescope_builtin.registers, { desc = "Find registers" })
vim.keymap.set("n", "<Leader>b", telescope_builtin.buffers, { desc = "Find buffers" })
vim.keymap.set("n", "<Leader>c", telescope_builtin.resume, { desc = "Resume picker" })
vim.keymap.set("n", "<Leader>f", telescope_builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<Leader>g", telescope_builtin.live_grep, { desc = "Find regexp pattern" })
vim.keymap.set("n", "<Leader>h", telescope_builtin.command_history, { desc = "Find Ex-mode history" })

local group = vim.api.nvim_create_augroup("LspAttachLauncherKeybinds", { clear = true })
vim.api.nvim_create_autocmd("LspAttach", {
	group = group,
	callback = function(event)
		vim.keymap.set(
			"n",
			"<Leader>w",
			telescope_builtin.diagnostics,
			{ desc = "Find workspace diagnostics", buffer = event.buf }
		)
		vim.keymap.set("n", "<Leader>d", function()
			telescope_builtin.diagnostics({ bufnr = 0 })
		end, { desc = "Find document diagnostics", buffer = event.buf })
		vim.keymap.set(
			"n",
			"<Leader>i",
			telescope_builtin.lsp_implementations,
			{ desc = "LSP implementations", buffer = event.buf }
		)
		vim.keymap.set(
			"n",
			"<Leader>r",
			telescope_builtin.lsp_references,
			{ desc = "LSP references", buffer = event.buf }
		)
	end,
})
