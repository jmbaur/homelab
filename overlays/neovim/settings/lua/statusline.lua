local utils = require("jmbaur.utils")

local statusline_hl = utils.resolve_hl("StatusLine")
local bg = statusline_hl.bg
if statusline_hl.reverse then
	bg = statusline_hl.fg
end

local error_hl = { bg = bg, fg = utils.resolve_hl("DiagnosticError").fg }
local hint_hl = { bg = bg, fg = utils.resolve_hl("DiagnosticHint").fg }
local info_hl = { bg = bg, fg = utils.resolve_hl("DiagnosticInfo").fg }
local warn_hl = { bg = bg, fg = utils.resolve_hl("DiagnosticWarn").fg }

vim.api.nvim_set_hl(0, "StatusLineDiagnosticError", error_hl)
vim.api.nvim_set_hl(0, "StatusLineDiagnosticHint", hint_hl)
vim.api.nvim_set_hl(0, "StatusLineDiagnosticInfo", info_hl)
vim.api.nvim_set_hl(0, "StatusLineDiagnosticWarn", warn_hl)

local diagnostics_config = {
	{ display = "E", severity = vim.diagnostic.severity.ERROR, hi = "StatusLineDiagnosticError" },
	{ display = "W", severity = vim.diagnostic.severity.WARN,  hi = "StatusLineDiagnosticWarn" },
	{ display = "I", severity = vim.diagnostic.severity.INFO,  hi = "StatusLineDiagnosticInfo" },
	{ display = "H", severity = vim.diagnostic.severity.HINT,  hi = "StatusLineDiagnosticHint" },
}

function StatusLine()
	local statusline_is_current_window = vim.fn.win_getid() == vim.g.statusline_winid

	if vim.bo.filetype == "fugitive" then
		return "%f"
	end

	local curr_diagnostics = {}
	for _, diag in ipairs(diagnostics_config) do
		local num_indicators = #vim.diagnostic.get(0, { severity = diag["severity"] })
		if num_indicators > 0 then
			-- Only apply the diagnostic highlight group if we are focused on
			-- the active window
			if statusline_is_current_window then
				table.insert(curr_diagnostics, "%#" .. diag["hi"] .. "#" .. diag["display"] .. num_indicators .. "%*")
			end
		end
	end

	local display_diagnostics = ""
	if #curr_diagnostics > 0 then
		display_diagnostics = display_diagnostics .. table.concat(curr_diagnostics, " ") .. " "
	end

	local statusline = "%.60f %m%r" .. "%=" .. display_diagnostics .. "%y %P"

	if vim.b.gitsigns_status_dict ~= nil and statusline_is_current_window then
		statusline = "[" .. vim.b.gitsigns_status_dict.head .. "] " .. statusline
	end

	return statusline
end

vim.opt.statusline = "%!v:lua.StatusLine()"
