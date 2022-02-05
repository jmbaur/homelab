local telescope = require "telescope"

telescope.setup {defaults = {layout_config = {vertical = {height = 1.0}}}}
telescope.load_extension("zf-native")

local function nnoremap(key, cmd)
    vim.api.nvim_set_keymap("n", key, '<cmd>' .. cmd .. "<cr>",
                            {noremap = true, silent = true})
end

nnoremap("<leader>f", "Telescope find_files")
nnoremap("<leader>g", "Telescope live_grep")
nnoremap("<leader>b", "Telescope buffers")
nnoremap("<leader>h", "Telescope help_tags")
