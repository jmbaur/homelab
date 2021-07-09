require'nvim-treesitter.configs'.setup {
  ensure_installed = "maintained",
  highlight = { enable = true, },
}

require('nvim-autopairs').setup()

vim.g.ayucolor = "dark"
vim.cmd('color ayu')

vim.opt.termguicolors = true
vim.opt.wrap = false
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.showmatch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.hidden = true
vim.opt.undofile = true
vim.opt.swapfile = false
vim.opt.foldenable = false
vim.opt.scrolloff = 5
vim.opt.sidescrolloff = 5
vim.opt.clipboard = 'unnamedplus'
vim.opt.foldmethod = 'indent'

vim.g.mapleader = ' '

local opts = { noremap = true, silent = true }

vim.api.nvim_set_keymap("n", "<C-L>", "<cmd>nohl<cr>", opts)
vim.api.nvim_set_keymap("n", "<leader>tf", "<cmd>lua require('telescope.builtin').find_files()<cr>", opts)
vim.api.nvim_set_keymap("n", "<leader>tg", "<cmd>lua require('telescope.builtin').live_grep()<cr>", opts)
vim.api.nvim_set_keymap("n", "<leader>tb", "<cmd>lua require('telescope.builtin').buffers()<cr>", opts)
vim.api.nvim_set_keymap("n", "<leader>th", "<cmd>lua require('telescope.builtin').help_tags()<cr>", opts)

local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<leader>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<leader>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<leader>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  buf_set_keymap('n', '<leader>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_set_keymap('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '<leader>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', '<leader>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
  buf_set_keymap("n", "<leader>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
end

local servers = { "gopls", "tsserver", "pyright", "bashls", "rnix", "hls" }
for _, lsp in ipairs(servers) do
  require('lspconfig')[lsp].setup { on_attach = on_attach }
end
