vim.g.cargo_makeprg_params = "build"

local group = vim.api.nvim_create_augroup("RustCompiler", { clear = true })
vim.api.nvim_create_autocmd({ "BufEnter" }, {
	pattern = { "*.rs", "Cargo.toml", "Cargo.lock" },
	group = group,
	desc = "Set Rust compiler",
	callback = function()
		if vim.fn.executable("cargo") == 1 then
			vim.cmd.compiler("cargo")
		else
			vim.cmd.compiler("rustc")
		end
	end,
})
