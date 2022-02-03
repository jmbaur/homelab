local lsp = require('lspconfig')

local format_on_save = [[
          augroup Format
            au! * <buffer>
            au BufWritePre <buffer> lua vim.lsp.buf.formatting_sync(nil, 1000)
          augroup END
]]

local on_attach = function(uses_efm)
    return function(client, bufnr)
        if (uses_efm) then
            client.resolved_capabilities.document_formatting = false
        elseif (client.resolved_capabilities.document_formatting) then
            vim.cmd(format_on_save)
        end

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
        buf_set_keymap('n', '<C-k>',
                       '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
        buf_set_keymap('n', '<leader>ca',
                       '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
        buf_set_keymap('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>',
                       opts)
        buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
        buf_set_keymap('n', '<leader>e',
                       '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
        buf_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>',
                       opts)
        buf_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>',
                       opts)
        buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
        buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
        buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>',
                       opts)
        buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    end
end

for k, v in pairs {
    clangd = {uses_efm = true},
    gopls = {uses_efm = true},
    pyright = {uses_efm = true},
    rust_analyzer = {uses_efm = true},
    sumneko_lua = {uses_efm = true},
    tsserver = {uses_efm = true},
    zls = {uses_efm = false}
} do
    lsp[k].setup {
        on_attach = on_attach(v.uses_efm),
        flags = {debounce_text_changes = 150}
    }
end

local sumneko_root_path = os.getenv("SUMNEKO_ROOT_PATH")
if sumneko_root_path ~= nil then
    lsp.sumneko_lua.setup {
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

-- local clang_format_options = {
--     {formatCommand = "clang-format --assume-filename=${INPUT}"},
--     formatStdin = true
-- }

local efm_languages = {
    go = {{formatCommand = "goimports", formatStdin = true}}, -- TODO(jared): use gopls formatting with some custom code that does imports
    lua = {{formatCommand = "lua-format -i", formatStdin = true}},
    nix = {{formatCommand = "nixpkgs-fmt", formatStdin = true}},
    python = {{formatCommand = "black --quiet -", formatStdin = true}},
    rust = {
        {
            formatCommand = 'rustfmt --emit stdout -q "${INPUT}"',
            formatStdin = true
        }
    },
    sh = {{formatCommand = "shfmt -ci -s -bn", formatStdin = true}}
}

lsp.efm.setup {
    on_attach = function() vim.cmd(format_on_save) end,
    init_options = {documentFormatting = true},
    settings = {rootMarkers = {".git/"}, languages = efm_languages},
    filetypes = vim.tbl_keys(efm_languages)
}
