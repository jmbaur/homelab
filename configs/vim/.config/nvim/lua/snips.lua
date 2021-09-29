require"snippets".snippets = {
    _global = {
        todo = "TODO(jared): ",
        date = function() return os.date() end,
        time = function() return tostring(os.time()) end
    }
}
