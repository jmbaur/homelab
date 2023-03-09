function DiagnosticStatus()
	if #vim.lsp.buf_get_clients() == 0 then
		return ""
	end

	local t = {}
	for _, diag in ipairs({
		{ display = "E", severity = vim.diagnostic.severity.ERROR },
		{ display = "W", severity = vim.diagnostic.severity.WARN },
		{ display = "H", severity = vim.diagnostic.severity.HINT },
	}) do
		table.insert(t, diag["display"] .. ":" .. #vim.diagnostic.get(0, { severity = diag["severity"] }))
	end

	return "[" .. table.concat(t, " ") .. "]"
end

function StatusLine()
	if vim.g.statusline_winid == vim.fn.win_getid() then
		return "%<%f %m%{FugitiveStatusline()}%r%=%24.(%y%{luaeval('DiagnosticStatus()')}%) %8.(%l,%c%) %P"
	else
		return "%<%f %m"
	end
end

vim.opt.statusline = "%!v:lua.StatusLine()"
