local fzf_lua = require("fzf-lua")

fzf_lua.setup({
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

fzf_lua.register_ui_select()

vim.keymap.set("n", "<Leader>?", fzf_lua.helptags, { desc = "Find help tags" })
vim.keymap.set("n", "<Leader>_", fzf_lua.registers, { desc = "Find registers" })
vim.keymap.set("n", "<Leader>b", fzf_lua.buffers, { desc = "Find buffers" })
vim.keymap.set("n", "<Leader>c", fzf_lua.resume, { desc = "Resume picker" })
vim.keymap.set("n", "<Leader>f", fzf_lua.files, { desc = "Find files" })
vim.keymap.set("n", "<Leader>g", fzf_lua.live_grep, { desc = "Find regexp pattern" })
vim.keymap.set("n", "<Leader>h", fzf_lua.command_history, { desc = "Find Ex-mode history" })

local group = vim.api.nvim_create_augroup("LspAttachLauncherKeybinds", { clear = true })
vim.api.nvim_create_autocmd("LspAttach", {
	group = group,
	callback = function(event)
		vim.keymap.set(
			"n",
			"<Leader>w",
			fzf_lua.diagnostics_workspace,
			{ desc = "Find workspace diagnostics", buffer = event.buf }
		)
		vim.keymap.set(
			"n",
			"<Leader>d",
			fzf_lua.diagnostics_document,
			{ desc = "Find document diagnostics", buffer = event.buf }
		)
		vim.keymap.set(
			"n",
			"<Leader>i",
			fzf_lua.lsp_implementations,
			{ desc = "LSP implementations", buffer = event.buf }
		)
		vim.keymap.set("n", "<Leader>r", fzf_lua.lsp_references, { desc = "LSP references", buffer = event.buf })
	end,
})
