local utils = require("jmbaur.utils")
local xterm = utils.xterm

if vim.fn.exists("syntax_on") then
	vim.cmd.syntax("reset")
end

-- reset colors
if vim.g.colors_name then
	vim.cmd.highlight({ args = { "clear" } })
end

vim.opt.background = "dark"
vim.opt.termguicolors = true

vim.g.colors_name = "jared"

local hi = function(group, args)
	vim.api.nvim_set_hl(0, group, args or {})
end
local link = function(from, to)
	vim.api.nvim_set_hl(0, from, { link = to })
end

-- editor highlight groups
hi("Normal", { fg = xterm[15], bg = xterm[0] }) -- Normal must be first
hi("ColorColumn", { bg = xterm[235] })
hi("Cursor", { fg = xterm[0], bg = "fg" })
hi("CursorLine", { ctermfg = "white" }) -- https://github.com/neovim/neovim/issues/9800
hi("CursorLineNr", { fg = "fg" })
hi("CursorLineSign", { italic = true })
hi("DiffAdd", { bg = "#0A290A" })
hi("DiffChange", { bg = "#222222" })
hi("DiffDelete", { fg = "#462022", bg = "#462022" })
hi("DiffText", { bg = "#343C19" })
hi("Error", { fg = "fg", bg = xterm[204] })
hi("FoldColumn", { fg = xterm[251], bg = xterm[235] })
hi("Folded", { fg = xterm[251], bg = xterm[235] })
hi("IncSearch", { reverse = true, fg = xterm[216], bg = xterm[232] })
hi("LineNr", { fg = xterm[242] })
hi("MatchParen", { bg = xterm[95] })
hi("NonText", { fg = xterm[242] })
hi("Pmenu", { fg = xterm[248], bg = xterm[235] })
hi("PmenuSbar", { bg = xterm[8] })
hi("PmenuSel", { fg = xterm[0], bg = "fg" })
hi("PmenuThumb", { bg = "fg" })
hi("Search", { fg = xterm[237], bg = xterm[185] })
hi("ShowMarksHL", { bold = true, fg = xterm[14], bg = xterm[81] })
hi("SignColumn", { fg = xterm[1], bg = "bg" })
hi("SpellBad", { undercurl = true, fg = xterm[204] })
hi("SpellCap", { undercurl = true })
hi("StatusLine", { bold = true, fg = xterm[235], bg = xterm[251] })
hi("StatusLineNC", { fg = xterm[244], bg = xterm[235] })
hi("TabLine", { fg = xterm[250], bg = xterm[235] })
hi("TabLineFill", { fg = xterm[235], bg = xterm[235] })
hi("TabLineSel", { bold = true, fg = "fg", bg = xterm[235] })
hi("Visual", { bg = xterm[109], fg = xterm[235] })
hi("WinBar", { fg = xterm[245], bg = xterm[235] })
hi("WinSeparator", { fg = xterm[252], bg = "bg" })
hi("diffAdded", { fg = xterm[72] })
hi("diffChanged", { bg = xterm[220] })
hi("diffRemoved", { fg = xterm[204] })
link("Error", "ErrorMsg")

-- code highlight groups
hi("Boolean", { fg = xterm[133] })
hi("Comment", { italic = true, fg = xterm[60] })
hi("Delimiter", { fg = xterm[248] })
hi("DiagnosticError", { fg = xterm[161] })
hi("DiagnosticHint", { fg = xterm[241] })
hi("DiagnosticInfo", { fg = xterm[241] })
hi("DiagnosticWarn", { fg = xterm[172] })
hi("Identifier", { fg = xterm[74] })
hi("Include", { fg = xterm[186] })
hi("Keyword", { fg = xterm[152] })
hi("Macro", { fg = xterm[134] })
hi("Number", { fg = xterm[143] })
hi("PreProc", { fg = xterm[137] })
hi("Statement", { fg = xterm[179] })
hi("String", { fg = xterm[72] })
hi("Title", { bold = true, fg = xterm[146] })
hi("Todo", { fg = xterm[232], bg = xterm[227] })
hi("Type", { fg = xterm[176] })

-- telescope.nvim highlight groups
link("TelescopeMatching", "Search")

-- gitsigns.nvim highlight groups
hi("GitSignsAdd", { fg = xterm[72], bg = "bg" })
hi("GitSignsChange", { fg = xterm[220], bg = "bg" })
hi("GitSignsDelete", { fg = xterm[204], bg = "bg" })

-- diffview.nvim highlight groups
hi("DiffviewStatusModified", { fg = xterm[220], bg = "bg" })
