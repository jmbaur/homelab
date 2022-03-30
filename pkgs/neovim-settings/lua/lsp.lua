local lspconfig = require('lspconfig')

local on_attach = function(client, bufnr)
    client.resolved_capabilities.document_formatting = false

    -- Prevent LSP preview window from opening on omnifunc
    vim.cmd [[set completeopt-=preview]]

    local function buf_set_keymap(...)
        vim.api.nvim_buf_set_keymap(bufnr, ...)
    end
    local function buf_set_option(...)
        vim.api.nvim_buf_set_option(bufnr, ...)
    end

    -- Enable completion triggered by <c-x><c-o>
    buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- Mappings.
    local opts = {noremap = true, silent = true}

    -- See `:help vim.lsp.*` for documentation on any of the below functions
    buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>',
                   opts)
    buf_set_keymap('n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>',
                   opts)
    buf_set_keymap('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
    buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
    buf_set_keymap('n', '<leader>e', '<cmd>lua vim.diagnostic.open_float()<CR>',
                   opts)
    buf_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
    buf_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
    buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
end

for _, lsp in pairs {
    "clangd", "gopls", "pyright", "rust_analyzer", "tsserver", "zls"
} do
    lspconfig[lsp].setup {
        on_attach = on_attach,
        flags = {debounce_text_changes = 150}
    }
end

local sumneko_root_path = os.getenv("SUMNEKO_ROOT_PATH")
if sumneko_root_path ~= nil then
    lspconfig.sumneko_lua.setup {
        cmd = {
            sumneko_root_path .. "/bin/lua-language-server", "-E",
            sumneko_root_path .. "/extras/main.lua"
        },
        on_attach = on_attach,
        settings = {Lua = {diagnostics = {globals = {"vim"}}}},
        flags = {debounce_text_changes = 150},
        telemetry = {enable = false}
    }
end
