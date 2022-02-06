require'neogit'.setup {kind = "split", disable_commit_confirmation = true}
vim.cmd [[
command -nargs=* G :Neogit <args>
]]
