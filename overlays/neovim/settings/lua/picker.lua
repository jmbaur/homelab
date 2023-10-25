local pick = require("mini.pick")
pick.setup({
	source = { show = pick.default_show },
})

vim.ui.select = pick.ui_select

-- TODO(jared): look into use cases for pick.builtin.cli
vim.keymap.set("n", "<leader>?", pick.builtin.help, { desc = "Find help" })
vim.keymap.set("n", "<leader>b", pick.builtin.buffers, { desc = "Find buffers" })
vim.keymap.set("n", "<leader>f", pick.builtin.files, { desc = "Find files" })
vim.keymap.set("n", "<leader>g", pick.builtin.grep_live, { desc = "Find regexp pattern" })
vim.keymap.set("n", "<leader>r", pick.builtin.resume, { desc = "Resume last pick" })

-- TODO(jared): don't do this, but the default link for MiniPickMatchCurrent
-- makes it unusable. Current colorscheme probably needs to be updated.
vim.cmd [[ highlight! link MiniPickMatchCurrent Done ]]

-- NOTE: pickers from telescope that do not (yet?) have matching pickers in mini.pick
-- vim.keymap.set("n", "<leader>_", telescope_builtins.registers, { desc = "Find registers" })
-- vim.keymap.set("n", "<leader>d", document_diagnostics, { desc = "Find document diagnostics" })
-- vim.keymap.set("n", "<leader>h", telescope_builtins.command_history, { desc = "Find Ex-mode history" })
-- vim.keymap.set("n", "<leader>w", telescope_builtins.diagnostics, { desc = "Find workspace diagnostics" })
