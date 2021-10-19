require"snippets".snippets = {
    _global = {
        todo = "TODO(jared): ",
        date = function() return os.date() end,
        time = function() return tostring(os.time()) end
    },
    go = {ife = [[if err != nil { $1 }]]},
    typescript = {
        log = [[console.log("${1}", $1)]],
        info = [[console.info("${1}", $1)]],
        error = [[console.error("${1}", $1)]]
    }
}

vim.cmd [[
    inoremap <c-j> <cmd>lua return require"snippets".advance_snippet(-1)<CR>
    inoremap <c-k> <cmd>lua return require"snippets".expand_or_advance(1)<CR>
]]
