require'neogit'.setup {}
vim.cmd [[
command -nargs=* G :Neogit <args>
]]
