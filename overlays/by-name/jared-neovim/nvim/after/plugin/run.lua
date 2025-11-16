local nix_path_contains_nixpkgs = function()
	return vim.fn.match(vim.trim(vim.system({ "nix", "config", "show", "nix-path" }):wait().stdout), "nixpkgs") ~= -1
end

-- Use a large tarball TTL value so invocations of 'nix shell' can be fast
local max_tarball_ttl = math.pow(2, 32) - 1

local nix_shell = function(attr, command)
	return function()
		if nix_path_contains_nixpkgs() then
			return string.format("nix shell --tarball-ttl %s nixpkgs\\#%s -c %s", max_tarball_ttl, attr, command)
		else
			return string.format(
				"nix shell --tarball-ttl %s github:nixos/nixpkgs/master\\#%s -c %s",
				max_tarball_ttl,
				attr,
				command
			)
		end
	end
end

local nix_run = function(attr)
	return nix_shell(attr, attr)
end

local nix_repl = function()
	return table.concat({ "nix", "repl", "--tarball-ttl", max_tarball_ttl }, " ")
end

local run_builtins = {
	bash = nix_run("bash"),
	bc = nix_run("bc"),
	deno = nix_run("deno"),
	ghci = nix_shell("ghc", "ghci"),
	lua = nix_run("lua"),
	nix = nix_repl,
	node = nix_shell("nodejs", "node"),
	python3 = nix_run("python3"),
}

vim.api.nvim_create_user_command("Run", function(opts)
	local cmd = {}

	if opts.mods ~= "" then
		table.insert(cmd, opts.mods)
	end

	table.insert(cmd, "terminal")

	if vim.tbl_contains(vim.tbl_keys(run_builtins), opts.args) then
		local builtin = run_builtins[opts.args]
		table.insert(cmd, type(builtin) == "function" and builtin() or builtin)
	elseif opts.args ~= "" then
		table.insert(cmd, nix_run(opts.args)())
	end

	vim.fn.execute(table.concat(cmd, " "))
end, {
	nargs = "?",
	---@diagnostic disable-next-line: unused-local
	complete = function(arg_lead, cmdline, cursor_pos)
		local candidates = {}

		for _, key in ipairs(vim.tbl_keys(run_builtins)) do
			if vim.fn.match(key, arg_lead) == 0 then
				table.insert(candidates, key)
			end
		end

		return candidates
	end,
})
