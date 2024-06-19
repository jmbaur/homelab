require("mini.diff").setup({})
require("mini.git").setup({})

-- depends on git-browse (in git-extras at https://github.com/tj/git-extras)
vim.api.nvim_create_user_command("Permalink", function(args)
	local branch = vim.trim(vim.system({ "git", "rev-parse", "--abbrev-ref", "HEAD" }):wait().stdout)
	local remote = vim.trim(vim.system({ "git", "config", string.format("branch.%s.remote", branch) }):wait().stdout)

	local git_browse_args = { "git", "browse", remote, vim.fn.expand("%"), args.line1 }

	if args.range > 0 then
		table.insert(git_browse_args, args.line2)
	end

	vim.print(vim.trim(vim.system(git_browse_args, {
		-- "git browse" calls xdg-open, so ensure that xdg-open prints to
		-- stdout by setting the following environment variables
		env = {
			BROWSER = "echo",
			DISPLAY = "",
			WAYLAND_DISPLAY = "",
		}
	}):wait().stdout))
end, { range = true, desc = "Get a permalink to source at line under cursor or selected range" })
