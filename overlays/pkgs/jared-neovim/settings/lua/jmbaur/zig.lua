local group = vim.api.nvim_create_augroup("ZigCompiler", { clear = true })
vim.api.nvim_create_autocmd({ "BufEnter" }, {
	pattern = { "*.zig", "*.zon" },
	group = group,
	desc = "Set Zig compiler",
	callback = function()
		if vim.fn.executable("zig") ~= 1 then
			return
		end

		-- If build.zig exists, assume it is a project that can be built with
		-- `zig build`, otherwise assume it is a single-file zig program that
		-- can be built with `zig build-exe`.
		if #vim.fs.find({ "build.zig" }, { type = "file" }) > 0 then
			vim.cmd.compiler("zig_build")
		else
			vim.cmd.compiler("zig_build_exe")
		end
	end,
})
