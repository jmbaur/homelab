local snippets = require('snippets')

snippets.snippets = {
  _global = {
    todo = 'TODO(jared): ',
    date = function() return os.date('!%Y-%m-%d') end,
    time = function() return os.date('!%Y-%m-%dT%TZ') end,
  },
  go = { iferr = [[if err != nil { $1 }]] },
  typescript = {
    log = [[console.log("${1}", $1)]],
    info = [[console.info("${1}", $1)]],
    error = [[console.error("${1}", $1)]],
  },
  zig = { print = [[std.debug.print("\n$1: {$2}\n\n", .{$1});]] },
}

vim.keymap.set({ 'i', 's' }, '<c-j> ', function() snippets.advance_snippet(-1) end, { desc = 'Advance snippet' })
vim.keymap.set(
  { 'i', 's' },
  '<c-k>',
  function() snippets.expand_or_advance(1) end,
  { desc = 'Expand or advance snippet' }
)
