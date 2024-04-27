require("mini.statusline").setup({
	use_icons = false
})

vim.api.nvim_set_hl(0, "MiniStatuslineFilename", { link = "MiniStatuslineDevinfo" })
vim.api.nvim_set_hl(0, "MiniStatuslineModeCommand", { link = "MiniStatuslineDevinfo" })
vim.api.nvim_set_hl(0, "MiniStatuslineModeInsert", { link = "MiniStatuslineDevinfo" })
vim.api.nvim_set_hl(0, "MiniStatuslineModeNormal", { link = "MiniStatuslineDevinfo" })
vim.api.nvim_set_hl(0, "MiniStatuslineModeOther", { link = "MiniStatuslineDevinfo" })
vim.api.nvim_set_hl(0, "MiniStatuslineModeReplace", { link = "MiniStatuslineDevinfo" })
vim.api.nvim_set_hl(0, "MiniStatuslineModeVisual", { link = "MiniStatuslineDevinfo" })
