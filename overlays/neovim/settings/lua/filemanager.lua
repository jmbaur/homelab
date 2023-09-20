local mini_files = require("mini.files")

-- don't show icons
mini_files.setup({ content = { prefix = function() end } })

vim.keymap.set("n", "-", function()
	MiniFiles.open(vim.api.nvim_buf_get_name(0))
end, { desc = "Open parent directory" })
