require"snippets".snippets = {
    _global = {
        todo = "TODO(jared): ",
        date = function() return os.date() end,
        time = function() return tostring(os.time()) end
    },
    go = {iferr = [[if err != nil { $1 }]]},
    typescript = {
        log = [[console.log("${1}", $1)]],
        info = [[console.info("${1}", $1)]],
        error = [[console.error("${1}", $1)]]
    },
    zig = {print = [[std.debug.print("\n$1: {$2}\n", .{$1});]]}
}

local function inoremap(key, cmd)
    vim.api.nvim_set_keymap("i", key, cmd, {noremap = true, silent = true})
end

inoremap("<c-j> ", "<cmd>lua return require\"snippets\".advance_snippet(-1)<CR>")
inoremap("<c-k>", "<cmd>lua return require\"snippets\".expand_or_advance(1)<CR>")
