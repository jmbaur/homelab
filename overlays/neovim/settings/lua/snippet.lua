require("snippets").snippets = {
	_global = {
		todo = "TODO(jared): ",
		date = function()
			return os.date("!%Y-%m-%d")
		end,
		time = function()
			return os.date("!%Y-%m-%dT%TZ")
		end,
	},
	go = { iferr = [[if err != nil { $1 }]] },
	typescript = {
		log = [[console.log("${1}", $1)]],
		info = [[console.info("${1}", $1)]],
		error = [[console.error("${1}", $1)]],
	},
	zig = { print = [[std.debug.print("\n$1: {$2}\n", .{$1});]] },
}

vim.keymap.set("i", "<c-j> ", function()
	require("snippets").advance_snippet(-1)
end)
vim.keymap.set("i", "<c-k>", function()
	require("snippets").expand_or_advance(1)
end)
