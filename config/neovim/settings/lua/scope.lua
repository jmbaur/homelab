require"telescope".setup {
    defaults = {layout_config = {vertical = {height = 1.0}}}
}

local function nnoremap(key, cmd)
    vim.api.nvim_set_keymap("n", key, '<cmd>' .. cmd .. "<cr>",
                            {noremap = true, silent = true})
end

nnoremap("<leader>f",
         "lua require('telescope.builtin').find_files({find_command={'rg','--ignore','--files'},layout_strategy='vertical',previewer=false,layout_config={height=0.95,width=0.95}})")
nnoremap("<leader>g", "Telescope live_grep")
nnoremap("<leader>b", "Telescope buffers")
nnoremap("<leader>h", "Telescope help_tags")
