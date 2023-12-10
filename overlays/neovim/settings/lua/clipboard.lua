vim.opt.clipboard = "unnamedplus"

local osc52 = require("vim.ui.clipboard.osc52")

vim.g.clipboard = {
	name = "OSC 52",
	copy = {
		["+"] = osc52.copy("+"),
		["*"] = osc52.copy("*"),
	},
	-- doesn't work well for all terminals (yet)
	-- paste = {
	-- 	["+"] = osc52.paste("+"),
	-- 	["*"] = osc52.paste("*"),
	-- },
}
