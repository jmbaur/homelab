vim.loader.enable()

vim.cmd.source('@langSupportLua@')

vim.g.mapleader = ' '

-- If not using nvim's remote UI
if #vim.api.nvim_list_uis() > 0 then
  vim.g.transparent_enabled = true

  vim.cmd.colorscheme('lunaperche')

  require('jmbaur.clipboard')
  require('jmbaur.compile')
  require('jmbaur.filemanager')
  require('jmbaur.git')
  require('jmbaur.launcher')
  require('jmbaur.lsp')
  require('jmbaur.readline')
  require('jmbaur.run').setup()
  require('jmbaur.sessions')
  require('jmbaur.snippets')
  require('jmbaur.treesitter')
  require('mini.trailspace').setup({})

  vim.opt.belloff = 'all'
  vim.opt.colorcolumn = '80'
  vim.opt.foldmethod = 'marker'
  vim.opt.title = true
end

require('mini.bracketed').setup({})
require('mini.surround').setup({})
require('mini.basics').setup({
  mappings = { basic = false },
  autocommands = { relnum_in_visual_mode = true },
})

vim.opt.shell = '/bin/sh' -- should exist everywhere
vim.opt.showmatch = true
vim.opt.cursorline = false -- undo what is done in mini.basics
