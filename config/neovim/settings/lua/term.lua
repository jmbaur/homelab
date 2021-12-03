require'toggleterm'.setup {}

local function nnoremap(key, cmd)
    vim.api.nvim_set_keymap("n", key, cmd .. "<cr>",
                            {noremap = true, silent = true})
end

nnoremap("<leader>t", "<cmd>ToggleTerm")
