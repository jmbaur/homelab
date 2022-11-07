local telescope = require("telescope")
local builtin = require("telescope.builtin")
local actions = require("telescope.actions")
local fuzzy = require("mini.fuzzy")

fuzzy.setup()

telescope.load_extension("ui-select")

telescope.setup({
	defaults = {
		generic_sorter = fuzzy.get_telescope_sorter,
		mappings = {
			i = { ["<C-b>"] = actions.file_split },
			n = { ["<C-b>"] = actions.file_split },
		},
	},
	pickers = {
		find_files = {
			find_command = { "fd", "--type", "f", "--strip-cwd-prefix", "--hidden" },
		},
	},
})

local document_diagnostics = function()
	builtin.diagnostics({ bufnr = 0 })
end

vim.keymap.set("n", "<leader>?", builtin.help_tags)
vim.keymap.set("n", "<leader>d", document_diagnostics) -- document diagnostics
vim.keymap.set("n", "<leader>w", builtin.diagnostics) -- workspace diagnostics
vim.keymap.set("n", "<leader>_", builtin.registers)
vim.keymap.set("n", "<leader>b", builtin.buffers)
vim.keymap.set("n", "<leader>f", builtin.find_files)
vim.keymap.set("n", "<leader>g", builtin.live_grep)
