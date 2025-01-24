local group = vim.api.nvim_create_augroup("TermOpen", { clear = true })

vim.api.nvim_create_autocmd("TermOpen", {
	group = group,
	callback = function()
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
		vim.opt_local.signcolumn = "no"
		vim.opt_local.spell = false
	end,
})
