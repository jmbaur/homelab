-- TODO(jared): get these dialed in
-- require("mini.diff").setup({})
-- require("mini.git").setup({})

-- -- Use BufNew since it is only called once on the creation of a new buffer,
-- -- unlike BufEnter, which is called everytime the buffer is entered
-- vim.api.nvim_create_autocmd({ "BufNew" }, {
-- 	desc = "Setup MiniDiff",
-- 	callback = function(args)
-- 		if not vim.api.nvim_buf_is_valid(args.buf) then return nil end
-- 		vim.b[args.buf or 0].minidiff_disable = true -- disabled by default, but toggleable
--
-- 		vim.api.nvim_buf_create_user_command(args.buf, "Diff", function()
-- 			vim.b[args.buf or 0].minidiff_disable = false
-- 			MiniDiff.toggle(args.buf)
-- 		end, { desc = "Toggle MiniDiff" })
-- 	end
-- })

-- depends on git-browse (in git-extras at https://github.com/tj/git-extras)
vim.api.nvim_create_user_command("Permalink", function(args)
	local current_file = vim.fn.expand("%")
	local repo_dir = vim.trim(vim.system({ "git", "-C", vim.fs.dirname(current_file), "rev-parse", "--show-toplevel" })
		:wait().stdout)
	local branch = vim.trim(vim.system({ "git", "-C", repo_dir, "rev-parse", "--abbrev-ref", "HEAD" }):wait().stdout)
	local remote = vim.trim(vim.system({ "git", "-C", repo_dir, "config", string.format("branch.%s.remote", branch) })
		:wait().stdout)
	local git_file = vim.trim(vim.system({ "git", "-C", repo_dir, "ls-files", current_file }):wait()
		.stdout)
	local git_browse_args = { "git", "-C", repo_dir, "browse", remote, git_file, args.line1 }

	if args.range > 0 then
		table.insert(git_browse_args, args.line2)
	end

	local url = vim.trim(vim.system(git_browse_args, {
		-- "git browse" calls xdg-open, so ensure that xdg-open prints to
		-- stdout by setting the following environment variables
		env = {
			BROWSER = "echo",
			DISPLAY = "",
			WAYLAND_DISPLAY = "",
		}
	}):wait().stdout)

	if args.bang then
		vim.fn.setreg("+", url)
	end

	vim.print(url)
end, {
	range = true,
	bang = true,
	desc = "Get a permalink to source at line under cursor or selected range",
})
