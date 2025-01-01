local stdout_or_bail = function(system_call)
	local res = system_call:wait()
	if res.code > 0 then
		error(vim.trim(res.stderr), vim.log.levels.ERROR)
	end

	return vim.trim(res.stdout)
end

local get_range = function(args)
	if args.range == 0 then
		return { nil, nil }
	end

	if args.line1 == args.line2 then
		return { args.line1, nil }
	end

	return { args.line1, args.line2 }
end

-- base_url_fmt: accepts 3 args (base url, git revision, & file path)
-- line1_fmt: accepts 1 arg (line 1)
-- line2_fmt: accepts 1 arg (line 2)
local construct_url = function(base_url_fmt, line1_fmt, line2_fmt)
	return function(args, remote_url, rev, git_file)
		local line1, line2 = unpack(get_range(args))
		local url = string.format(base_url_fmt, remote_url, rev, git_file)
		if line1 ~= nil then
			url = url .. string.format(line1_fmt, line1)
		end
		if line2 ~= nil then
			url = url .. string.format(line2_fmt, line2)
		end
		return url
	end
end

local construct_sourcehut_url = construct_url("%s/tree/%s/item/%s", "#L%s", "-%s")
local construct_gitlab_url = construct_url("%s/-/blob/%s/%s", "#L%s", "-%s")
local construct_github_url = construct_url("%s/blob/%s/%s", "#L%s", "-L%s")

local construct_gitea_url = function(args, remote_url, rev, git_file)
	local line1, line2 = unpack(get_range(args))
	local url = string.format("%s/src/commit/%s/%s", remote_url, rev, git_file)
	if line1 ~= nil then
		url = string.format("%s#L%s", url, line1)
	end
	if line2 ~= nil then
		url = string.format("%s-L%s", url, line2)
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

	local repo_dir =
		stdout_or_bail(vim.system({ "git", "-C", vim.fs.dirname(current_file), "rev-parse", "--show-toplevel" }))

	local branch = stdout_or_bail(vim.system({ "git", "-C", repo_dir, "branch", "--show-current" }))

	-- If HEAD is detached, nothing is printed
	if branch == "" then
		vim.notify("detached HEAD, cannot get permalink", vim.log.levels.ERROR)
		return
	end

	local remote =
		stdout_or_bail(vim.system({ "git", "-C", repo_dir, "config", string.format("branch.%s.remote", branch) }))

	local git_file = stdout_or_bail(vim.system({ "git", "-C", repo_dir, "ls-files", current_file }))

	local remote_url = stdout_or_bail(vim.system({ "git", "-C", repo_dir, "remote", "get-url", remote }))
	remote_url = string.gsub(remote_url, "git%+ssh://.*@", "https://")

	local rev = stdout_or_bail(vim.system({ "git", "-C", repo_dir, "rev-parse", "HEAD" }))

	local url = nil

	if string.match(remote_url, "^https?://github.com/.*") then
		url = construct_github_url(args, remote_url, rev, git_file)
	elseif string.match(remote_url, "^https?://gitlab.com/.*") then
		url = construct_gitlab_url(args, remote_url, rev, git_file)
	elseif string.match(remote_url, "^https://git.sr.ht/.*") then
		url = construct_sourcehut_url(args, remote_url, rev, git_file)
	else
		local forge_type_config = string.format("remote.%s.forge-type", remote)
		local git_config_res = vim.system({ "git", "-C", repo_dir, "config", "get", forge_type_config }):wait()
		if git_config_res.code == 0 then
			local forge_type = vim.trim(git_config_res.stdout)
			if forge_type == "github" then
				url = construct_github_url(args, remote_url, rev, git_file)
			elseif forge_type == "gitlab" then
				url = construct_gitlab_url(args, remote_url, rev, git_file)
			elseif forge_type == "gitea" then
				url = construct_gitea_url(args, remote_url, rev, git_file)
			else
				-- We got a forge type we don't know about, unset it
				vim.system({ "git", "-C", repo_dir, "config", "unset", forge_type_config }):wait()
			end
		else
			local github_header_regex = vim.regex("^x-github-request-id: .*$")
			local gitlab_header_regex = vim.regex("^x-gitlab-meta: .*$")
			local gitea_header_regex = vim.regex("^set-cookie: .*i_like_gitea.*$")

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
				elseif gitea_header_regex:match_str(header) then
					url = construct_gitea_url(args, remote_url, rev, git_file)
					set_forge_type(repo_dir, forge_type_config, "gitea")
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
