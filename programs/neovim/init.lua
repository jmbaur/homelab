-- Ensure packer is installed
local fn = vim.fn
local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({
        'git', 'clone', 'https://github.com/wbthomason/packer.nvim',
        install_path
    })
    vim.cmd [[packadd packer.nvim]]
end

require'packer'.startup(function(use)
    -- let packer manage itself
    use 'wbthomason/packer.nvim'
    -- colorscheme
    use {
        "ellisonleao/gruvbox.nvim",
        requires = {"rktjmp/lush.nvim"},
        config = function()
            vim.o.background = "dark" -- or "light" for light mode
            vim.cmd([[colorscheme gruvbox]])
        end
    }
    -- language specific plugins
    use 'LnL7/vim-nix'
    use 'leafgarland/typescript-vim'
    use 'neovimhaskell/haskell-vim'
    use 'ziglang/zig.vim'
    -- tpope
    use 'tpope/vim-fugitive'
    use 'tpope/vim-repeat'
    use 'tpope/vim-rsi'
    use 'tpope/vim-surround'
    -- misc
    use 'ntpeters/vim-better-whitespace'
    -- neovim specific plugins
    use {
        'blackCauldron7/surround.nvim',
        disable = true,
        config = function()
            vim.g.surround_mappings_style = 'surround'
            require'surround'.setup {}
        end
    }
    use {
        'b3nj5m1n/kommentary',
        config = function()
            require'kommentary.config'.configure_language('default', {
                prefer_single_line_comments = true
            })
        end
    }
    use {
        'windwp/nvim-autopairs',
        config = function() require'nvim-autopairs'.setup {} end
    }
    use {'nacro90/numb.nvim', config = function() require'numb'.setup {} end}
    use 'neovim/nvim-lspconfig'
    use 'folke/lsp-colors.nvim'
    use {
        'nvim-treesitter/nvim-treesitter',
        run = ':TSUpdate',
        config = function()
            require'nvim-treesitter.configs'.setup {
                ensure_installed = 'maintained',
                highlight = {enable = true}
            }
        end
    }
    use 'norcalli/snippets.nvim'
    use {
        'nvim-telescope/telescope.nvim',
        requires = {{'nvim-lua/plenary.nvim'}}
    }
    use 'mfussenegger/nvim-dap'
end)

vim.g.mapleader = ','
vim.o.clipboard = 'unnamedplus'
vim.o.colorcolumn = '80'
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
local lspconfig = require 'lspconfig'
local function common_on_attach()
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
    buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
    buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>',
                   opts)
    buf_set_keymap('n', '<space>wa',
                   '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<space>wr',
                   '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<space>wl',
                   '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>',
                   opts)
    buf_set_keymap('n', '<space>D',
                   '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
    buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
    buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>',
                   opts)
    buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    buf_set_keymap('n', '<space>e',
                   '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>',
                   opts)
    buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>',
                   opts)
    buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>',
                   opts)
    buf_set_keymap('n', '<space>q',
                   '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
    buf_set_keymap('n', '<space>f', '<cmd>lua vim.lsp.buf.formatting()<CR>',
                   opts)

    -- format on save
    vim.api.nvim_command(
        "autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync(nil, 1000)")
end
local basic_servers = {'bashls', 'yamlls', 'rnix', 'hls', 'pyright', 'zls'}
for _, lsp in ipairs(basic_servers) do
    lspconfig[lsp].setup {
        on_attach = common_on_attach,
        flags = {debounce_text_changes = 150}
    }
end

function Go_organize_imports(wait_ms)
    local params = vim.lsp.util.make_range_params()
    params.context = {only = {"source.organizeImports"}}
    local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction",
                                            params, wait_ms)

    for _, res in pairs(result or {}) do
        for _, r in pairs(res.result or {}) do
            if r.edit then
                vim.lsp.util.apply_workspace_edit(r.edit)
            else
                vim.lsp.buf.execute_command(r.command)
            end
        end
    end
end
lspconfig.gopls.setup {
    on_attach = function()
        common_on_attach()
        vim.api.nvim_command(
            "autocmd BufWritePre *.go lua Go_organize_imports(1000)")
    end,
    flags = {debounce_text_changes = 150}
}

lspconfig.tsserver.setup {
    on_attach = common_on_attach,
    flags = {debounce_text_changes = 150},
    commands = {
        OrganizeImports = {
            function()
                vim.lsp.buf.execute_command {
                    command = '_typescript.organizeImports',
                    arguments = {vim.api.nvim_buf_get_name(0)},
                    title = ''
                }
            end,
            description = 'Organize Imports'
        }
    }

}

local f = io.popen("readlink $(which lua-language-server)", "r")
local sumneko_bin = string.gsub(f:read("*a"), "%s+", "")
local sumneko_main = sumneko_bin .. "/../../extras/main.lua"
f:close()

lspconfig.sumneko_lua.setup {
    on_attach = common_on_attach,
    cmd = { sumneko_bin, "-E", sumneko_main },
    settings = {Lua = {diagnostics = {globals = {'vim', 'bufnr'}}}},
    telemetry = {enable = false}
}

-- snippets
require'snippets'.snippets = {
    _global = {
        todo = 'TODO(jared): ',
        date = function() return os.date() end,
        time = function() return os.time() end
    }
}
vim.cmd [[inoremap <c-k> <cmd>lua return require'snippets'.expand_or_advance(1)<CR>]]
vim.cmd [[inoremap <c-j> <cmd>lua return require'snippets'.advance_snippet(-1)<CR>]]

-- telescope
vim.cmd [[nnoremap <leader>ff <cmd>lua require('telescope.builtin').find_files()<cr>]]
vim.cmd [[nnoremap <leader>fg <cmd>lua require('telescope.builtin').live_grep()<cr>]]
vim.cmd [[nnoremap <leader>fb <cmd>lua require('telescope.builtin').buffers()<cr>]]
vim.cmd [[nnoremap <leader>fh <cmd>lua require('telescope.builtin').help_tags()<cr>]]
