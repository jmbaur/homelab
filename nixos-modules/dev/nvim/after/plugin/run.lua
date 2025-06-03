local nix_shell = function(attr, command)
	return string.format("nix shell nixpkgs\\#%s -c %s", attr, command)
end

local nix_run = function(attr)
	return nix_shell(attr, attr)
end

local run_builtins = {
	bash = nix_run("bash"),
	bc = nix_run("bc"),
	deno = nix_run("deno"),
	ghci = nix_shell("ghc", "ghci"),
	lua = nix_run("lua"),
	nix = 'nix repl --file "<nixpkgs>"',
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
		table.insert(cmd, run_builtins[opts.args])
	else
		table.insert(nix_run(opts.args))
	end

	vim.fn.execute(table.concat(cmd, " "))
end, {
	nargs = 1,
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
