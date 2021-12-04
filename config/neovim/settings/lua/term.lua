require'toggleterm'.setup {}

local function noremap(mode, key, cmd)
    vim.api.nvim_set_keymap(mode, key, cmd .. "<cr>",
                            {noremap = true, silent = true})
end

noremap("n", "<leader>t", "<cmd>ToggleTerm")
noremap("t", "<leader>t", "<cmd>ToggleTerm")
