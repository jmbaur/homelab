local stdout_or_bail = function(result)
	if result.code > 0 then
		error(vim.trim(result.stderr), vim.log.levels.ERROR)
	end

	return vim.trim(result.stdout)
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

local forges = {
	github = construct_url("%s/blob/%s/%s", "#L%s", "-L%s"),
	gitlab = construct_url("%s/-/blob/%s/%s", "#L%s", "-%s"),
	sourcehut = construct_url("%s/tree/%s/item/%s", "#L%s", "-%s"),
	gitea = construct_url("%s/src/commit/%s/%s", "#L%s", "-L%s"),
}

local github_header_regex = vim.regex("^x-github-request-id: .*$")
local gitlab_header_regex = vim.regex("^x-gitlab-meta: .*$")
local gitea_header_regex = vim.regex("^set-cookie: .*i_like_gitea.*$")

local detect_forge = function(remote_url)
	local headers = vim.split(stdout_or_bail(vim.system({ "curl", "--silent", "--head", remote_url }):wait()), "\r\n")

	for _, header in ipairs(headers) do
		if github_header_regex:match_str(header) then
			return "github"
		elseif gitlab_header_regex:match_str(header) then
			return "gitlab"
		elseif gitea_header_regex:match_str(header) then
			return "gitea"
		end
	end

	error("forge type not detected", vim.log.levels.ERROR)
end

vim.api.nvim_create_user_command("Permalink", function(opts)
	local current_file = vim.fn.expand("%")

	local repo_dir =
		stdout_or_bail(vim.system({ "git", "-C", vim.fs.dirname(current_file), "rev-parse", "--show-toplevel" }):wait())

	local git_command = function(rest)
		local cmd = { "git", "-C", repo_dir }
		for _, val in ipairs(rest) do
			table.insert(cmd, val)
		end
		return vim.system(cmd):wait()
	end

	local git_file = stdout_or_bail(git_command({ "ls-files", current_file }))

	if git_command({ "diff", "HEAD" }).code > 0 then
		error("working tree is dirty", vim.log.levels.ERROR)
	end

	local remote_refspecs = vim.tbl_filter(function(value)
		return vim.fn.match(value, ".*\\/HEAD -> .*") ~= 0
	end, vim.split(stdout_or_bail(git_command({ "branch", "--points-at", "HEAD", "--remotes" })), "\n"))

	if #remote_refspecs == 0 then
		error("no remote branches found that point at HEAD", vim.log.levels.ERROR)
	end

	local remote = vim.trim(vim.fn.substitute(remote_refspecs[1], "\\/.*", "", ""))
	local remote_url = stdout_or_bail(git_command({ "remote", "get-url", remote }))
	remote_url = string.gsub(remote_url, "git%+ssh://.*@", "https://")

	local rev = stdout_or_bail(git_command({ "rev-parse", "HEAD" }))

	local url = nil

	local forge_fn = nil

	if string.match(remote_url, "^https?://github.com/.*$") then
		forge_fn = forges["github"]
	elseif string.match(remote_url, "^https?://gitlab.com/.*$") then
		forge_fn = forges["gitlab"]
	elseif string.match(remote_url, "^https://git.sr.ht/.*$") then
		forge_fn = forges["sourcehut"]
	else
		local forge = vim.trim(git_command({ "config", "get", string.format("remote.%s.forge-type", remote) }).stdout)
		if forge == "" then
			forge = detect_forge(remote_url)
			git_command({ "config", "set", string.format("remote.%s.forge-type", remote), forge })
		end

		forge_fn = forges[forge]
	end

	if forge_fn == nil then
		error("unknown forge type", vim.log.levels.ERROR)
	end

	local url = forge_fn(opts, remote_url, rev, git_file)

	if opts.bang then
		vim.fn.setreg("+", url)
	end

	vim.print(url)
end, {
	range = true,
	bang = true,
	desc = "Get a permalink to source at line under cursor or selected range",
})
