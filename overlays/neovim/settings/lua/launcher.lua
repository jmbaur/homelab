local fzf = require("fzf-lua")
local actions = require("fzf-lua.actions")

fzf.setup({
	fzf_bin = "sk",
	files = {
		file_icons = false,
		git_icons = false,
		actions = {
			-- override the default action for horizontal split
			["ctrl-b"] = actions.file_split,
		},
	},
	grep = {
		file_icons = false,
		git_icons = false,
	},
	lsp = {
		file_icons = false,
		git_icons = false,
	},
	diagnostics = {
		file_icons = false,
		git_icons = false,
	},
})

fzf.register_ui_select()

vim.keymap.set("n", "<leader>?", fzf.help_tags, { desc = "Find help tags" })
vim.keymap.set("n", "<leader>_", fzf.registers, { desc = "Find registers" })
vim.keymap.set("n", "<leader>b", fzf.buffers, { desc = "Find buffers" })
vim.keymap.set("n", "<leader>d", fzf.lsp_document_diagnostics, { desc = "Find document diagnostics" })
vim.keymap.set("n", "<leader>f", fzf.files, { desc = "Find files" })
vim.keymap.set("n", "<leader>g", fzf.live_grep, { desc = "Find regexp pattern" })
vim.keymap.set("n", "<leader>h", fzf.command_history, { desc = "Find Ex-mode history" })
vim.keymap.set("n", "<leader>w", fzf.lsp_workspace_diagnostics, { desc = "Find workspace diagnostics" })
