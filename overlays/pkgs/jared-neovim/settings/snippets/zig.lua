local zig_snippets = {}

for _, fn in ipairs({ "err", "warn", "info", "debug" }) do
	zig_snippets[fn] = { prefix = fn, body = string.format('@import("std").log.%s("$1={${2:any}}", .{$1});', fn) }
end

return zig_snippets
