local diagnostics_config = {
	{ display = "E", severity = vim.diagnostic.severity.ERROR, hi = "StatusLineDiagnosticError" },
	{ display = "W", severity = vim.diagnostic.severity.WARN,  hi = "StatusLineDiagnosticWarn" },
	{ display = "I", severity = vim.diagnostic.severity.INFO,  hi = "StatusLineDiagnosticInfo" },
	{ display = "H", severity = vim.diagnostic.severity.HINT,  hi = "StatusLineDiagnosticHint" },
}

function StatusLine()
	if vim.bo.filetype == "fugitive" then
		return "%{FugitiveStatusline()} %f"
	else
		local curr_diagnostics = {}
		for _, diag in ipairs(diagnostics_config) do
			local num_indicators = #vim.diagnostic.get(0, { severity = diag["severity"] })
			if num_indicators > 0 then
				-- Only apply the diagnostic highlight group if we are focused on
				-- the active window
				if vim.g.statusline_winid == vim.fn.win_getid() then
					table.insert(curr_diagnostics, "%#" .. diag["hi"] .. "#" .. diag["display"] .. num_indicators .. "%*")
				else
					table.insert(curr_diagnostics, diag["display"] .. num_indicators)
				end
			end
		end

		local display_diagnostics = ""
		if #curr_diagnostics > 0 then
			display_diagnostics = display_diagnostics .. table.concat(curr_diagnostics, " ") .. " "
		end

		return "%.60f %m%r" .. "%=" .. display_diagnostics .. "%y %P"
	end
end

vim.opt.statusline = "%!v:lua.StatusLine()"
