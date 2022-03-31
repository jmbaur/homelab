local nixpkgs_fmt = function()
    return {exe = "nixpkgs-fmt", args = {}, stdin = true}
end

local prettier = function()
    return {
        exe = "prettier",
        args = {
            "--stdin-filepath", vim.fn.fnameescape(vim.api.nvim_buf_get_name(0))
        },
        stdin = true
    }
end

local goimports = function()
    return {
        exe = "goimports",
        args = {"-w", vim.fn.fnameescape(vim.api.nvim_buf_get_name(0))},
        stdin = false
    }
end

local black = function() return {exe = "black", args = {'-'}, stdin = true} end

local rustfmt = function()
    return {
        exe = "rustfmt",
        args = {"--emit=stdout", "--edition=2021"},
        stdin = true
    }
end

local lua_format = function()
    return {exe = "lua-format", args = {"-i"}, stdin = true}
end

local shfmt =
    function() return {exe = "shfmt", args = {"-i", 2}, stdin = true} end

local latexindent = function()
    return {exe = "latexindent", args = {"-"}, stdin = true}
end

local filetypes = {
    go = {goimports},
    javascript = {prettier},
    lua = {lua_format},
    nix = {nixpkgs_fmt},
    python = {black},
    rust = {rustfmt},
    sh = {shfmt},
    tex = {latexindent},
    typescript = {prettier},
    yaml = {prettier}
}

vim.api.nvim_exec([[
augroup FormatAutogroup
  autocmd!
  autocmd BufWritePost *.go,*.js,*.lua,*.nix,*.py,*.rs,*.sh,*.tex,*.ts,*.yaml,*.yml FormatWrite
augroup END
]], true)

require'formatter'.setup {filetype = filetypes}
