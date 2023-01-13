local M = {}

local make_builtin = function(executable_name, fallback)
	return function()
		if executable_name ~= nil and vim.fn.executable(executable_name) == 1 then
			return executable_name
		elseif fallback ~= nil then
			return fallback
		else
			return os.getenv("SHELL")
		end
	end
end

local make_nix_shell_builtin = function(executable_name, nix_package_name)
	local fallback = nil
	if nix_package_name ~= nil then
		fallback = string.format("nix shell nixpkgs\\#%s --command %s", nix_package_name, executable_name)
	end
	return make_builtin(executable_name, fallback)
end

local make_nix_run_builtin = function(executable_name, nix_run_fallback)
	return make_builtin(executable_name, string.format("nix run nixpkgs\\#%s", nix_run_fallback or executable_name))
end

local nix_repl = function()
	return 'nix repl --file "<nixpkgs>"'
end

local current_shell = function()
	return os.getenv("SHELL")
end

M.builtins = {
	["bash"] = make_nix_run_builtin("bash"),
	["bc"] = make_nix_run_builtin("bc"),
	["clj"] = make_nix_run_builtin("clj", "clojure"),
	["dash"] = make_nix_run_builtin("dash"),
	["deno"] = make_nix_run_builtin("deno"),
	["erl"] = make_nix_shell_builtin("erl", "erlang"),
	["fish"] = make_nix_run_builtin("fish"),
	["fsharpi"] = make_nix_shell_builtin("fsharpi", "fsharp"),
	["ghci"] = make_nix_shell_builtin("ghci", "ghc"),
	["guile"] = make_nix_run_builtin("guile"),
	["lua"] = make_nix_run_builtin("lua"),
	["nix"] = nix_repl,
	["nodejs"] = make_nix_run_builtin("node", "nodejs"),
	["ocaml"] = make_nix_run_builtin("ocaml"),
	["oil"] = make_nix_run_builtin("oil"),
	["python3"] = make_nix_run_builtin("python3"),
	["shell"] = current_shell,
	["zsh"] = make_nix_run_builtin("zsh"),
}

M.start_repl = function(cmd_fn)
	cmd_fn = M.builtins[cmd_fn]
	if cmd_fn ~= nil then
		vim.cmd.vsplit(string.format("term://%s", cmd_fn()))
	else
		vim.notify("no repl command provided")
	end
end

M.select_results = {}
for display_name in pairs(M.builtins) do
	table.insert(M.select_results, display_name)
end

M.launch = function()
	vim.ui.select(M.select_results, {
		prompt = "Repl:",
	}, M.start_repl)
end

M.setup = function()
	vim.keymap.set("n", "<leader>$", M.launch, { desc = "Launch REPL chooser" })
	vim.api.nvim_create_user_command("Repl", function(args)
		local arg
		if args["args"] == "" then
			arg = "shell"
		else
			arg = args["args"]
		end
		M.start_repl(arg)
	end, {
		nargs = "*",
		desc = "nvim-repl",
		complete = function(arg_lead, cmd_line, cursor_pos)
			local completions = {}
			for k in pairs(M.builtins) do
				local i, _ = string.find(k, arg_lead)
				if i == 1 then
					table.insert(completions, k)
				end
			end
			return completions
		end,
	})
end

return M
