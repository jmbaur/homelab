local lsp = require('lspconfig')

function OrganizeImports(wait_ms)
    local params = vim.lsp.util.make_range_params()
    params.context = {only = {"source.organizeImports"}}
    local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction",
                                            params, wait_ms)
    for _, res in pairs(result or {}) do
        for _, r in pairs(res.result or {}) do
            if r.edit then
                vim.lsp.util.apply_workspace_edit(r.edit, "utf-16")
            else
                vim.lsp.buf.execute_command(r.command)
            end
        end
    end
end

local format_on_save = [[
    autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync(nil, 1000)
]]

local organize_imports_on_save = [[
    autocmd BufWritePre <buffer> lua OrganizeImports(nil, 1000)
]]

local on_attach = function(cfg)
    return function(client, bufnr)
        if cfg.uses_efm then
            client.resolved_capabilities.document_formatting = false
        elseif client.resolved_capabilities.document_formatting then
            vim.cmd(format_on_save)
        end

        if cfg.organize_imports then vim.cmd(organize_imports_on_save) end

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
    clangd = {uses_efm = false},
    gopls = {uses_efm = false, organize_imports = true},
    pyright = {uses_efm = true},
    rust_analyzer = {uses_efm = true},
    sumneko_lua = {uses_efm = true},
    tsserver = {uses_efm = true},
    zls = {uses_efm = false}
} do
    lsp[k]
        .setup {on_attach = on_attach(v), flags = {debounce_text_changes = 150}}
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

local efm_languages = {
    lua = {{formatCommand = "lua-format -i", formatStdin = true}},
    nix = {{formatCommand = "nixpkgs-fmt", formatStdin = true}},
    python = {{formatCommand = "black --quiet -", formatStdin = true}},
    rust = {
        {
            formatCommand = 'rustfmt --emit stdout -q "${INPUT}"',
            formatStdin = true
        }
    },
    sh = {{formatCommand = "shfmt -ci -s -bn", formatStdin = true}},
    javascript = {
        {
            formatCommand = "clang-format --assume-filename=foobar.js",
            formatStdin = true
        }
    },
    typescript = {
        {
            formatCommand = "clang-format --assume-filename=foobar.ts",
            formatStdin = true
        }
    },
    tex = {{formatCommand = "latexindent", formatStdin = true}}
}

lsp.efm.setup {
    on_attach = function() vim.cmd(format_on_save) end,
    init_options = {documentFormatting = true},
    settings = {rootMarkers = {".git/"}, languages = efm_languages},
    filetypes = vim.tbl_keys(efm_languages)
}
