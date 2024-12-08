local M = {}

local run_command = function(executable_name, fallback_command)
	return function()
		if vim.fn.executable(executable_name) == 1 then
			return executable_name
		else
			return fallback_command
		end
	end
end

-- Ensures that if a command is not executable and in PATH, `nix shell` can be
-- used as a fallback to obtain the correct executable to run.
local run_command_nix_shell_wrapper = function(executable_name, nix_package_name)
	local fallback =
		string.format("nix shell nixpkgs\\#%s --command %s", nix_package_name or executable_name, executable_name)

	return run_command(executable_name, fallback)
end

local nix_repl = function()
	return "nix repl --expr 'import <nixpkgs> { }'"
end

local shell = function()
	return os.getenv("SHELL") or "/bin/sh"
end

M.builtins = {
	["bash"] = run_command_nix_shell_wrapper("bash", nil),
	["bc"] = run_command_nix_shell_wrapper("bc", nil),
	["clj"] = run_command_nix_shell_wrapper("clj", "clojure"),
	["deno"] = run_command_nix_shell_wrapper("deno", nil),
	["erl"] = run_command_nix_shell_wrapper("erl", "erlang"),
	["fsharpi"] = run_command_nix_shell_wrapper("fsharpi", "fsharp"),
	["ghci"] = run_command_nix_shell_wrapper("ghci", "ghc"),
	["guile"] = run_command_nix_shell_wrapper("guile", nil),
	["lua"] = run_command_nix_shell_wrapper("lua", nil),
	["nix"] = nix_repl,
	["nodejs"] = run_command_nix_shell_wrapper("node", "nodejs"),
	["ocaml"] = run_command_nix_shell_wrapper("ocaml", nil),
	["python3"] = run_command_nix_shell_wrapper("python3", nil),
	["shell"] = shell,
}

M.run = function(cmd)
	if cmd == nil then
		return
	end

	local cmd_fn = M.builtins[cmd]
	if cmd_fn ~= nil then
		cmd = cmd_fn()
	end

	vim.cmd.terminal(cmd)
end

M.select_results = {}
for display_name in pairs(M.builtins) do
	table.insert(M.select_results, display_name)
end

M.launch = function()
	vim.ui.select(M.select_results, { prompt = "Run:" }, M.run)
end

M.setup = function()
	vim.keymap.set("n", "<leader>$", M.launch, { desc = "Launch Run chooser" })
	vim.api.nvim_create_user_command("Run", function(args)
		local arg
		if args["args"] == "" then
			arg = "shell"
		else
			arg = args["args"]
		end
		M.run(arg)
	end, {
		nargs = "*",
		desc = "Run a REPL",
		complete = function(arg_lead, cmd_line, cursor_pos)
			_, _ = cmd_line, cursor_pos

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
