function diagnostics_status()
	local status = { "[lsp]" }
	if #vim.lsp.buf_get_clients() > 0 then
		for _, severity in ipairs({
			{ display = "E", severity = vim.diagnostic.severity.ERROR },
			{ display = "W", severity = vim.diagnostic.severity.WARN },
			{ display = "H", severity = vim.diagnostic.severity.HINT },
			{ display = "I", severity = vim.diagnostic.severity.INFO },
		}) do
			table.insert(
				status,
				severity["display"] .. ":" .. #vim.diagnostic.get(0, { severity = severity["severity"] })
			)
		end
	else
		table.insert(status, "_")
	end
	return table.concat(status, " ")
end

vim.opt.statusline = "%{luaeval('diagnostics_status()')}%=%f %{FugitiveStatusline()}%=%y%m%r %l,%c %P"
