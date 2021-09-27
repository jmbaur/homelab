vim.cmd [[colorscheme gruvbox]]
vim.cmd [[nnoremap n nzzzv]]
vim.cmd [[nnoremap N Nzzzv]]
vim.cmd [[nnoremap J mzJ`z]]
vim.cmd [[inoremap , ,<c-g>u]]
vim.cmd [[inoremap . .<c-g>u]]
vim.cmd [[inoremap ! !<c-g>u]]
vim.cmd [[inoremap ? ?<c-g>u]]
vim.cmd [[nnoremap <expr> k (v:count > 5 ? "m'" . v:count : "") . "k"]]
vim.cmd [[nnoremap <expr> j (v:count > 5 ? "m'" . v:count : "") . "j"]]

require"numb".setup {}
require"nvim-autopairs".setup {}
require"nvim-treesitter.configs".setup {
    ensure_installed = "maintained",
    highlight = {enable = true}
}
require"kommentary.config".configure_language("default", {
    prefer_single_line_comments = true
})

vim.g.mapleader = ","
vim.o.clipboard = "unnamedplus"
vim.o.colorcolumn = "80"
vim.o.cursorline = false
vim.o.expandtab = true
vim.o.hidden = true
vim.o.ignorecase = true
vim.o.number = true
vim.o.relativenumber = true
vim.o.scrolloff = 5
vim.o.shiftwidth = 2
vim.o.showmatch = true
vim.o.sidescrolloff = 5
vim.o.smartcase = true
vim.o.softtabstop = 2
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.tabstop = 2
vim.o.termguicolors = true
vim.o.wrap = false

-- LSP
local lspconfig = require "lspconfig"
local function on_attach(_, bufnr)
    local function lsp_nmap(mapping, cmd)
        local opts = {noremap = true, silent = true}
        vim.api.nvim_buf_set_keymap(bufnr, "n", mapping,
                                    "<cmd>" .. cmd .. "<CR>", opts)
    end
    local function buf_set_option(...)
        vim.api.nvim_buf_set_option(bufnr, ...)
    end

    -- Enable completion triggered by <c-x><c-o>
    buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")

    -- See `:help vim.lsp.*` for documentation on any of the below functions
    lsp_nmap("<C-k>", "lua vim.lsp.buf.signature_help()")
    lsp_nmap("<leader>D", "lua vim.lsp.buf.type_definition()")
    lsp_nmap("<leader>ca", "lua vim.lsp.buf.code_action()")
    lsp_nmap("<leader>e", "lua vim.lsp.diagnostic.show_line_diagnostics()")
    lsp_nmap("<leader>q", "lua vim.lsp.diagnostic.set_loclist()")
    lsp_nmap("<leader>rn", "lua vim.lsp.buf.rename()")
    lsp_nmap("K", "lua vim.lsp.buf.hover()")
    lsp_nmap("[d", "lua vim.lsp.diagnostic.goto_prev()")
    lsp_nmap("]d", "lua vim.lsp.diagnostic.goto_next()")
    lsp_nmap("gD", "lua vim.lsp.buf.declaration()")
    lsp_nmap("gd", "lua vim.lsp.buf.definition()")
    lsp_nmap("gi", "lua vim.lsp.buf.implementation()")
    lsp_nmap("gr", "lua vim.lsp.buf.references()")

    -- format on save
    vim.cmd [[
        augroup Format
          au! * <buffer>
          au BufWritePre <buffer> lua vim.lsp.buf.formatting_sync(nil, 1000)
        augroup END
    ]]
end

local basic_servers = {"bashls", "yamlls", "rnix", "hls", "pyright", "zls"}
for _, lsp in ipairs(basic_servers) do
    lspconfig[lsp].setup {
        on_attach = on_attach,
        flags = {debounce_text_changes = 150}
    }
end

lspconfig.gopls.setup {
    on_attach = function(client)
        client.resolved_capabilities.document_formatting = false
        on_attach(client)
    end,
    flags = {debounce_text_changes = 150}
}

lspconfig.tsserver.setup {
    on_attach = function(client)
        client.resolved_capabilities.document_formatting = false
        on_attach(client)
    end,
    flags = {debounce_text_changes = 150},
    commands = {
        OrganizeImports = {
            function()
                vim.lsp.buf.execute_command {
                    command = "_typescript.organizeImports",
                    arguments = {vim.api.nvim_buf_get_name(0)},
                    title = ""
                }
            end,
            description = "Organize Imports"
        }
    }
}

local goimports = {formatCommand = "goimports", formatStdin = true}
local lua_format = {formatCommand = "lua-format -i", formatStdin = true}
local prettier = {
    formatCommand = "prettier --stdin-filepath ${INPUT}",
    formatStdin = true
}
lspconfig.efm.setup {
    on_attach = on_attach,
    init_options = {documentFormatting = true, codeAction = true},
    settings = {
        rootMarkers = {".git/"},
        languages = {
            lua = {lua_format},
            javascript = {prettier},
            go = {goimports},
            json = {prettier},
            markdown = {prettier},
            typescript = {prettier},
            yaml = {prettier}
        }
    },
    filetypes = {
        "lua", "javascript", "json", "markdown", "typescript", "yaml", "go"
    }
}

lspconfig.sumneko_lua.setup {
    on_attach = function(client, bufnr)
        client.resolved_capabilities.document_formatting = false
        on_attach(client, bufnr)
    end,
    cmd = {Sumneko_bin, "-E", Sumneko_main},
    settings = {Lua = {diagnostics = {globals = {"vim"}}}},
    telemetry = {enable = false}
}

-- reassigned variables defined in ./neovim.nix so that the LSP is happy
Sumneko_bin = ""
Sumneko_main = ""

-- snippets
require"snippets".snippets = {
    _global = {
        todo = "TODO(jared): ",
        date = function() return os.date() end,
        time = function() return tostring(os.time()) end
    }
}
vim.cmd [[inoremap <c-k> <cmd>lua return require"snippets".expand_or_advance(1)<CR>]]
vim.cmd [[inoremap <c-j> <cmd>lua return require"snippets".advance_snippet(-1)<CR>]]

-- telescope
vim.cmd [[nnoremap <leader>ff <cmd>lua require("telescope.builtin").find_files()<cr>]]
vim.cmd [[nnoremap <leader>fg <cmd>lua require("telescope.builtin").live_grep()<cr>]]
vim.cmd [[nnoremap <leader>fb <cmd>lua require("telescope.builtin").buffers()<cr>]]
vim.cmd [[nnoremap <leader>fh <cmd>lua require("telescope.builtin").help_tags()<cr>]]
