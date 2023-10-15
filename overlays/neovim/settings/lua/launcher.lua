local telescope = require("telescope")
local telescope_builtins = require("telescope.builtin")

local document_diagnostics = function()
	telescope_builtins.diagnostics({ bufnr = 0 })
end

local M = {}
M.setup = function()
	telescope.load_extension("ui-select")

	vim.keymap.set("n", "<leader>?", telescope_builtins.help_tags, { desc = "Find help tags" })
	vim.keymap.set("n", "<leader>_", telescope_builtins.registers, { desc = "Find registers" })
	vim.keymap.set("n", "<leader>b", telescope_builtins.buffers, { desc = "Find buffers" })
	vim.keymap.set("n", "<leader>d", document_diagnostics, { desc = "Find document diagnostics" })
	vim.keymap.set("n", "<leader>f", telescope_builtins.find_files, { desc = "Find files" })
	vim.keymap.set("n", "<leader>g", telescope_builtins.live_grep, { desc = "Find regexp pattern" })
	vim.keymap.set("n", "<leader>h", telescope_builtins.command_history, { desc = "Find Ex-mode history" })
	vim.keymap.set("n", "<leader>w", telescope_builtins.diagnostics, { desc = "Find workspace diagnostics" })
end

M.lsp_implementations = telescope_builtins.lsp_implementations
M.lsp_references = telescope_builtins.lsp_references

return M
