local mini_files = require("mini.files")

-- don't show icons
mini_files.setup({ content = { prefix = function() end } })

vim.keymap.set("n", "-", MiniFiles.open, { desc = "Open parent directory" })
