require("oil").setup({ columns = {} })

vim.keymap.set("n", "-", vim.cmd.Oil, { desc = "Open parent directory" })
