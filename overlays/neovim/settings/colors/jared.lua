local xterm = require("xterm")

if vim.fn.exists("syntax_on") then
	vim.cmd.syntax("reset")
end

-- reset colors
if vim.g.colors_name then
	vim.cmd.highlight({ args = { "clear" } })
end

vim.opt.background = "dark"
vim.opt.cursorline = true
vim.opt.termguicolors = true

vim.g.colors_name = "jared"

-- USAGE:
-- hi("HighlightGroup", { attr = "attr-name", fg = "fg-color", bg = "bg-color" })
local hi = function(group, args)
	args = args or {}
	local attr = args["attr"]
	local fg = args["fg"]
	local bg = args["bg"]
	local sp = args["sp"]
	local highlight_args = { group }
	if attr ~= nil then
		table.insert(highlight_args, "gui=" .. attr)
	end
	if fg ~= nil then
		table.insert(highlight_args, "guifg=" .. fg)
	end
	if bg ~= nil then
		table.insert(highlight_args, "guibg=" .. bg)
	end
	if sp ~= nil then
		table.insert(highlight_args, "guisp=" .. sp)
	end
	if #highlight_args > 1 then
		vim.cmd.highlight({ args = highlight_args })
	end
end

local link = function(from, to)
	vim.cmd.highlight({ args = { "link", from, to } })
end

-- editor highlight groups
hi("ColorColumn", { bg = xterm[235] })
hi("Cursor", { fg = xterm[0], bg = xterm[15] })
hi("CursorLine", { attr = "NONE", bg = "NONE" })
hi("CursorLineNr", { attr = "NONE", fg = xterm[15] })
hi("CursorLineSign", { attr = "italic" })
hi("DiffAdd", { bg = "#406452" })
hi("DiffChange", { gui = "NONE", bg = xterm[235] })
hi("DiffDelete", { fg = "#9C455B", bg = "#9C455B" })
hi("DiffText", { gui = "NONE", bg = xterm[58] })
hi("Error", { fg = xterm[15], bg = xterm[204] })
hi("FoldColumn", { fg = xterm[251], bg = xterm[235] })
hi("Folded", { fg = xterm[251], bg = xterm[235] })
hi("IncSearch", { attr = "reverse", fg = xterm[216], bg = xterm[232] })
hi("LineNr", { fg = xterm[242] })
hi("MatchParen", { bg = xterm[95] })
hi("NonText", { fg = xterm[242], bg = "NONE" })
hi("Normal", { fg = xterm[15], bg = "NONE" })
hi("Pmenu", { fg = xterm[248], bg = xterm[235] })
hi("PmenuSbar", { bg = xterm[8] })
hi("PmenuSel", { fg = xterm[0], bg = xterm[15] })
hi("PmenuThumb", { bg = xterm[15] })
hi("Search", { fg = xterm[237], bg = xterm[185] })
hi("ShowMarksHL", { attr = "bold", fg = xterm[14], bg = xterm[81] })
hi("SignColumn", { fg = xterm[1], bg = "NONE" })
hi("SpellBad", { attr = "underlineitalic", fg = xterm[204] }) -- TODO(jared): use undercurl
hi("SpellCap", { attr = "underlineitalic" }) -- TODO(jared): use undercurl
hi("StatusLine", { fg = xterm[251], bg = xterm[232] })
hi("StatusLineNC", { attr = "NONE", fg = xterm[255], bg = xterm[235] })
hi("TabLine", { attr = "NONE", fg = xterm[250], bg = xterm[235] })
hi("TabLineFill", { fg = xterm[235], bg = xterm[235] })
hi("TabLineSel", { fg = xterm[15], bg = xterm[235] })
hi("Visual", { bg = xterm[109], fg = xterm[235] })
hi("WinBar", { fg = xterm[245], bg = xterm[235] })
hi("WinSeparator", { fg = xterm[252], bg = "NONE" })
hi("diffAdded", { fg = xterm[72] })
hi("diffChanged", { bg = xterm[220] })
hi("diffRemoved", { fg = xterm[204] })
link("Error", "ErrorMsg")
link("TelescopeMatching", "Search")

-- code highlight groups
hi("Boolean", { fg = xterm[133] })
hi("Character")
hi("Comment", { attr = "italic", fg = xterm[60] })
hi("Constant")
hi("Delimiter", { fg = xterm[248] })
hi("DiagnosticError", { fg = xterm[161] })
hi("DiagnosticHint", { fg = xterm[241] })
hi("DiagnosticInfo", { fg = xterm[241] })
hi("DiagnosticWarn", { fg = xterm[172] })
hi("Function")
hi("Identifier")
hi("Identifier", { fg = xterm[74] })
hi("Include", { fg = xterm[186] })
hi("Keyword", { fg = xterm[152] })
hi("Label")
hi("Macro", { fg = xterm[134] })
hi("Number", { fg = xterm[143] })
hi("Operator")
hi("PreProc", { fg = xterm[137] })
hi("Statement", { attr = "NONE", fg = xterm[179] })
hi("String", { fg = xterm[72] })
hi("Title", { attr = "bold", fg = xterm[146] })
hi("Type", { attr = "NONE", fg = xterm[176] })
link("@text.danger", "ErrorMsg")
link("@text.note", "SpecialComment")
link("@text.title", "Title")
