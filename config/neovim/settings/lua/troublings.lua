require'trouble'.setup {
    icons = false,
    fold_open = "v", -- icon used for open folds
    fold_closed = ">", -- icon used for closed folds
    indent_lines = false, -- add an indent guide below the fold icons
    signs = {
        -- icons / text used for a diagnostic
        error = "error",
        warning = "warn",
        hint = "hint",
        information = "info"
    },
    use_lsp_diagnostic_signs = false -- enabling this will use the signs defined in your lsp client
}

vim.api.nvim_set_keymap("n", "<leader>w",
                        "<cmd>TroubleToggle workspace_diagnostics<cr>",
                        {silent = true, noremap = true})
vim.api.nvim_set_keymap("n", "<leader>d",
                        "<cmd>TroubleToggle document_diagnostics<cr>",
                        {silent = true, noremap = true})
vim.api.nvim_set_keymap("n", "gR", "<cmd>TroubleToggle lsp_references<cr>",
                        {silent = true, noremap = true})
