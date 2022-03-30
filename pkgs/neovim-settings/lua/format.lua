vim.api.nvim_exec([[
augroup FormatAutogroup
  autocmd!
  autocmd BufWritePost *.nix,*.ts,*.go,*.py,*.rs,*.lua,*.sh,*.tex FormatWrite
augroup END
]], true)

require'formatter'.setup {
    filetype = {
        nix = {
            function()
                return {exe = "nixpkgs-fmt", args = {}, stdin = true}
            end
        },
        typescript = {
            function()
                return {
                    exe = "clang-format",
                    args = {"--assume-filename", vim.api.nvim_buf_get_name(0)},
                    stdin = true,
                    cwd = vim.fn.expand('%:p:h') -- Run clang-format in cwd of the file.
                }
            end
        },
        go = {
            function()
                return {
                    exe = "goimports",
                    args = {
                        "-w", vim.fn.fnameescape(vim.api.nvim_buf_get_name(0))
                    },
                    stdin = false
                }
            end
        },
        python = {
            function()
                return {exe = "black", args = {'-'}, stdin = true}
            end
        },
        rust = {
            function()
                return {
                    exe = "rustfmt",
                    args = {"--emit=stdout", "--edition=2021"},
                    stdin = true
                }
            end
        },
        lua = {
            function()
                return {exe = "lua-format", args = {"-i"}, stdin = true}
            end
        },
        sh = {
            function()
                return {exe = "shfmt", args = {"-i", 2}, stdin = true}
            end
        },
        tex = {
            function()
                return {exe = "latexindent", args = {"-"}, stdin = true}
            end
        }
    }
}
