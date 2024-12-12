local fzf_lua = require("fzf-lua")

fzf_lua.setup({ "skim" })

local M = {}

M.setup = function()
	fzf_lua.register_ui_select()

	vim.keymap.set("n", "<leader>?", fzf_lua.helptags, { desc = "Find help tags" })
	vim.keymap.set("n", "<leader>_", fzf_lua.registers, { desc = "Find registers" })
	vim.keymap.set("n", "<leader>b", fzf_lua.buffers, { desc = "Find buffers" })
	vim.keymap.set("n", "<leader>c", fzf_lua.resume, { desc = "Resume picker" })
	vim.keymap.set("n", "<leader>d", fzf_lua.diagnostics_document, { desc = "Find document diagnostics" })
	vim.keymap.set("n", "<leader>f", fzf_lua.files, { desc = "Find files" })
	vim.keymap.set("n", "<leader>g", fzf_lua.live_grep, { desc = "Find regexp pattern" })
	vim.keymap.set("n", "<leader>h", fzf_lua.command_history, { desc = "Find Ex-mode history" })
	vim.keymap.set("n", "<leader>t", fzf_lua.tabs, { desc = "Find tabs" })
	vim.keymap.set("n", "<leader>w", fzf_lua.diagnostics_workspace, { desc = "Find workspace diagnostics" })
end

M.lsp_implementations = fzf_lua.lsp_implementations
M.lsp_references = fzf_lua.lsp_references

return M
