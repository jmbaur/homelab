local telescope = require("telescope")
local builtin = require("telescope.builtin")
local actions = require("telescope.actions")
local fuzzy = require("mini.fuzzy")

telescope.setup({
	defaults = {
		generic_sorter = fuzzy.get_telescope_sorter,
		mappings = {
			i = { ["<C-b>"] = actions.file_split },
			n = { ["<C-b>"] = actions.file_split },
		},
	},
	pickers = {
		live_grep = { previewer = false },
		find_files = {
			find_command = { "fd", "--type", "f", "--strip-cwd-prefix", "--hidden" },
		},
	},
})

fuzzy.setup({})

telescope.load_extension("ui-select")

local document_diagnostics = function()
	builtin.diagnostics({ bufnr = 0 })
end

vim.keymap.set("n", "<leader>?", builtin.help_tags, { desc = "Find help tags" })
vim.keymap.set("n", "<leader>d", document_diagnostics, { desc = "Find document diagnostics" })
vim.keymap.set("n", "<leader>w", builtin.diagnostics, { desc = "Find workspace diagnostics" })
vim.keymap.set("n", "<leader>_", builtin.registers, { desc = "Find registers" })
vim.keymap.set("n", "<leader>b", builtin.buffers, { desc = "Find buffers" })
vim.keymap.set("n", "<leader>f", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>g", builtin.live_grep, { desc = "Find regexp pattern" })
