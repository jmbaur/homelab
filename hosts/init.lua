-- Ensure packer is installed
local fn = vim.fn
local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({
        'git', 'clone', 'https://github.com/wbthomason/packer.nvim',
        install_path
    })
    vim.cmd 'packadd packer.nvim'
end

require'packer'.startup(function(use)
    -- let packer manage itself
    use 'wbthomason/packer.nvim'
    -- colorscheme
    use 'tjdevries/colorbuddy.nvim'
    -- language specific plugins
    use 'neovimhaskell/haskell-vim'
    use 'LnL7/vim-nix'
    use 'leafgarland/typescript-vim'
    -- tpope
    use 'tpope/vim-fugitive'
    use 'tpope/vim-rsi'
    use 'tpope/vim-surround'
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
vim.o.termguicolors = true
vim.o.shiftwidth = 2
vim.o.tabstop = 2
vim.o.softtabstop = 2
vim.o.expandtab = true
vim.o.wrap = false
vim.o.showmatch = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.hidden = true
vim.o.number = true
vim.o.relativenumber = true
vim.o.cursorline = true
vim.o.scrolloff = 5
vim.o.sidescrolloff = 5
vim.o.clipboard = 'unnamedplus'

-- LSP
local lspconfig = require 'lspconfig'
local function organize_imports()
    local params = {
        command = '_typescript.organizeImports',
        arguments = {vim.api.nvim_buf_get_name(0)},
        title = ''
    }
    vim.lsp.buf.execute_command(params)
end
local on_attach = function(client, bufnr)
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
end
local servers = {'gopls', 'bashls', 'yamlls', 'rnix', 'hls', 'pyright'}
for _, lsp in ipairs(servers) do
    lspconfig[lsp].setup {
        on_attach = on_attach,
        flags = {debounce_text_changes = 150}
    }
end

lspconfig.tsserver.setup {
    on_attach = on_attach,
    flags = {debounce_text_changes = 150},
    commands = {
        OrganizeImports = {organize_imports, description = 'Organize Imports'}
    }
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

-- colorbuddy
local Color, colors, Group, groups, styles = require'colorbuddy'.setup {}

-- black
Color.new('color0', '#000000')
Color.new('color8', '#767676')
-- red
Color.new('color1', '#cc0403')
Color.new('color9', '#f2201f')
-- green
Color.new('color2', '#19cb00')
Color.new('color10', '#23fd00')
-- yellow
Color.new('color3', '#cecb00')
Color.new('color11', '#fffd00')
-- blue
Color.new('color4', '#0d73cc')
Color.new('color12', '#1a8fff')
-- magenta
Color.new('color5', '#cb1ed1')
Color.new('color13', '#fd28ff')
-- cyan
Color.new('color6', '#0dcdcd')
Color.new('color14', '#14ffff')
-- white
Color.new('color7', '#dddddd')
Color.new('color15', '#ffffff')

Group.new('Comment', colors.color2, nil, styles.italic)
Group.new('CursorLine', nil, nil, nil)
Group.new('CursorLineNr', colors.color7, nil, styles.bold)
Group.new('LineNr', colors.color8, nil, nil)
Group.new('NonText', colors.color8, nil, nil)
Group.new('Pmenu', nil, colors.color8, nil)
Group.new('PmenuSbar', nil, colors.color13, styles.bold)
Group.new('PmenuSel', nil, colors.color5, nil)
Group.new('PmenuThumb', nil, nil, nil)
Group.new('Search', colors.color0, colors.color11, nil)
Group.new('SignColumn', nil, colors.color0, nil)
Group.new('StatusLine', colors.color0, colors.color7, styles.bold)
Group.new('StatusLineNC', colors.color8, colors.color7, nil)
Group.new('Visual', nil, colors.color8, nil)
-- Group.new('')
