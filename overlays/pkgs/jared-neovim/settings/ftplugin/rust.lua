vim.g.cargo_makeprg_params = "build"

vim.api.nvim_create_autocmd({ "BufEnter" }, {
	pattern = { "*.rs" },
	group = vim.api.nvim_create_augroup("RustCompiler", {}),
	desc = "Set Rust compiler",
	once = true,
	callback = function()
		if vim.fn.executable("cargo") == 1 then
			vim.cmd.compiler("cargo")
		else
			vim.cmd.compiler("rustc")
		end
	end,
})
