require'telescope'.setup {
    defaults = {
        layout_config = {
            vertical = {width = 0.5}
            -- other layout configuration here
        }
        -- other defaults configuration here
    }
    -- other configuration values here

}

vim.cmd [[
    nnoremap <leader>f <cmd>Telescope find_files<cr>
    nnoremap <leader>g <cmd>Telescope live_grep<cr>
    nnoremap <leader>b <cmd>Telescope buffers<cr>
    nnoremap <leader>h <cmd>Telescope help_tags<cr>
]]
