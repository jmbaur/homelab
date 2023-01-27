function diagnostic_status()
	if #vim.lsp.buf_get_clients() == 0 then
		return "--"
	end

	local t = {}
	for _, diag in ipairs({
		{ display = "E", severity = vim.diagnostic.severity.ERROR },
		{ display = "W", severity = vim.diagnostic.severity.WARN },
		{ display = "H", severity = vim.diagnostic.severity.HINT },
	}) do
		table.insert(t, diag["display"] .. ":" .. #vim.diagnostic.get(0, { severity = diag["severity"] }))
	end

	return "[lsp] " .. table.concat(t, " ")
end

vim.opt.statusline = "%{luaeval('diagnostic_status()')}"
	.. "%="
	.. "%f %{FugitiveStatusline()}"
	.. "%="
	.. "%y%m%r %l,%c %P"
