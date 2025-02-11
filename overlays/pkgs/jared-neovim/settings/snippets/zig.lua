local zig_snippets = {}

for _, fn in ipairs({ "err", "warn", "info", "debug" }) do
	zig_snippets[fn] = { prefix = fn, body = string.format('@import("std").log.%s("$1={${2:any}}", .{$1});', fn) }
end

zig_snippets["print"] = { prefix = "print", body = '@import("std").debug.print("$1={${2:any}}\\n", .{$1});' }

return zig_snippets
