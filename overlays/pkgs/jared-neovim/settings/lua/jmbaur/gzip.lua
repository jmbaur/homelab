local group = vim.api.nvim_create_augroup("Devicetree", { clear = true })

vim.api.nvim_create_autocmd({ "BufReadPre", "FileReadPre" }, {
	group = group,
	pattern = "*.dtb",
	callback = function()
		vim.opt_local.binary = true
	end,
})

vim.api.nvim_create_autocmd({ "BufReadPost", "FileReadPost" }, {
	group = group,
	pattern = "*.dtb",
	callback = function()
		vim.fn["gzip#read"]("dtc_vim")
	end,
})

vim.api.nvim_create_autocmd({ "BufWritePost", "FileWritePost" }, {
	group = group,
	pattern = "*.dtb",
	callback = function()
		vim.fn["gzip#write"]("dtc_vim")
	end,
})

-- TODO(jared): do we even need to support these append operations?

vim.api.nvim_create_autocmd({ "FileAppendPre" }, {
	group = group,
	pattern = "*.dtb",
	callback = function()
		vim.fn["gzip#appre"]("dtc_vim")
	end,
})

vim.api.nvim_create_autocmd({ "FileAppendPost" }, {
	group = group,
	pattern = "*.dtb",
	callback = function()
		vim.fn["gzip#write"]("dtc_vim")
	end,
})
