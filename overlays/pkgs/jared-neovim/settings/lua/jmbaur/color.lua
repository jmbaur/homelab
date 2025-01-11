local group = vim.api.nvim_create_augroup("ColorScheme", { clear = true })
vim.api.nvim_create_autocmd({ "ColorScheme" }, {
	group = group,
	callback = function(args)
		_ = args

		local colorscheme = vim.fn.expand("<amatch>")
		if colorscheme == "default" then
			-- The default colorscheme doesn't have great highlights for the
			-- selected tabline, make it stand out more here.
			local tabline_sel = vim.api.nvim_get_hl(0, { name = "TablineSel" })
			tabline_sel["link"] = "Normal"

			---@diagnostic disable-next-line: param-type-mismatch
			vim.api.nvim_set_hl(0, "TablineSel", tabline_sel)
		elseif colorscheme == "lunaperche" then
			vim.api.nvim_set_hl(0, "WinSeparator", {})
		end
	end,
})

vim.cmd.colorscheme("lunaperche")
