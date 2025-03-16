local rust_snippets = {}

for _, fn in ipairs({ "eprintln" }) do
	rust_snippets[fn] = { prefix = fn, body = string.format('%s!("$1={${2::?}}", .{$1});', fn) }
end

return rust_snippets
