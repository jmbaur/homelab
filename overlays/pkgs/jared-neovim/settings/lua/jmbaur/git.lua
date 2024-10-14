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

local stdout_or_bail = function(system_call)
	local res = system_call:wait()
	if res.code > 0 then
		error(vim.trim(res.stderr), vim.log.levels.ERROR)
	end

	return vim.trim(res.stdout)
end

-- https://gitlab.com/<user_or_group>/<repo>/-/blob/<commit_or_branch>/<filename>#L<line1>-<line2>
local construct_gitlab_url = function(args, remote_url, rev, git_file)
	local url = string.format("%s/-/blob/%s/%s#L%s", remote_url, rev, git_file, args.line1)
	if args.range > 0 then
		url = string.format("%s-%s", url, args.line2)
	end
	return url
end

-- https://github.com/<user_or_org>/<repo>/blob/<commit_or_branch>/<filename>#L<line1>-L<line2>
local construct_github_url = function(args, remote_url, rev, git_file)
	local url = string.format("%s/blob/%s/%s#L%s", remote_url, rev, git_file, args.line1)
	if args.range > 0 then
		url = string.format("%s-L%s", url, args.line2)
	end
	return url
end

local set_forge_type = function(repo_dir, forge_type_config, forge_type)
	local res = vim.system({ "git", "-C", repo_dir, "config", "set", forge_type_config, forge_type }):wait()
	if res.code > 0 then
		vim.notify(res.stderr, vim.log.levels.ERROR)
	end
end

vim.api.nvim_create_user_command("Permalink", function(args)
	local current_file = vim.fn.expand("%")

	local repo_dir = stdout_or_bail(vim.system({ "git", "-C", vim.fs.dirname(current_file), "rev-parse",
		"--show-toplevel" }))

	local branch = stdout_or_bail(vim.system({ "git", "-C", repo_dir, "rev-parse", "--abbrev-ref", "HEAD" }))

	local remote = stdout_or_bail(vim.system({ "git", "-C", repo_dir, "config", string.format("branch.%s.remote", branch) }))

	local git_file = stdout_or_bail(vim.system({ "git", "-C", repo_dir, "ls-files", current_file }))

	local remote_url = stdout_or_bail(vim.system({ "git", "-C", repo_dir, "remote", "get-url", remote }))
	remote_url = string.gsub(remote_url, "git%+ssh://.*@", "https://")

	local rev = stdout_or_bail(vim.system({ "git", "-C", repo_dir, "rev-parse", "HEAD" }))

	local url = nil

	if string.match(remote_url, "^https?://github.com/.*") then
		url = construct_github_url(args, remote_url, rev, git_file)
	elseif string.match(remote_url, "^https?://gitlab.com/.*") then
		url = construct_gitlab_url(args, remote_url, rev, git_file)
	else
		local forge_type_config = string.format("remote.%s.forge-type", remote)
		local git_config_res = vim.system({ "git", "-C", repo_dir, "config", "get", forge_type_config }):wait()
		if git_config_res.code == 0 then
			local forge_type = vim.trim(git_config_res.stdout)
			if forge_type == "github" then
				url = construct_github_url(args, remote_url, rev, git_file)
			elseif forge_type == "gitlab" then
				url = construct_gitlab_url(args, remote_url, rev, git_file)
			else
				-- We got a forge type we don't know about, unset it
				vim.system({ "git", "-C", repo_dir, "config", "unset", forge_type_config }):wait()
			end
		else
			local github_header_regex = vim.regex("^x-github-request-id: .*$")
			local gitlab_header_regex = vim.regex("^x-gitlab-meta: .*$")

			local headers = vim.split(stdout_or_bail(vim.system({ "curl", "--head", remote_url })), "\r\n")

			for _, header in ipairs(headers) do
				if github_header_regex:match_str(header) then
					url = construct_github_url(args, remote_url, rev, git_file)
					set_forge_type(repo_dir, forge_type_config, "github")
					break
				elseif gitlab_header_regex:match_str(header) then
					url = construct_gitlab_url(args, remote_url, rev, git_file)
					set_forge_type(repo_dir, forge_type_config, "gitlab")
					break
				end
			end
		end
	end

	if url then
		if args.bang then
			vim.fn.setreg("+", url)
		end
		vim.print(url)
	else
		vim.notify("Could not detect git forge", vim.log.levels.ERROR)
	end
end, {
	range = true,
	bang = true,
	desc = "Get a permalink to source at line under cursor or selected range",
})
