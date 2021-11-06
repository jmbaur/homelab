require"telescope".setup {}

local function nnoremap(key, cmd)
    vim.api.nvim_set_keymap("n", key, cmd .. " " .. "previewer=false" .. "<cr>",
                            {noremap = true, silent = true})
end

nnoremap("<leader>f", "<cmd>Telescope find_files")
nnoremap("<leader>g", "<cmd>Telescope live_grep")
nnoremap("<leader>b", "<cmd>Telescope buffers")
nnoremap("<leader>h", "<cmd>Telescope help_tags")
