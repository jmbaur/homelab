local add_lsp = function(name, opts)
	vim.lsp.config(name, opts)
	vim.lsp.enable(name)
end

if vim.fn.executable("nil") == 1 then
	add_lsp("nil", {
		cmd = { "nil" },
		filetypes = { "nix" },
		root_markers = { "flake.nix", "default.nix", "shell.nix" },
		settings = {
			["nil"] = {
				formatting = { command = { "nixfmt" } },
				nix = { flake = { autoArchive = false } },
			},
		},
	})
end

if vim.fn.executable("rust-analyzer") == 1 then
	add_lsp("rust-analyzer", {
		cmd = { "rust-analyzer" },
		filetypes = { "rust" },
		root_markers = { "Cargo.toml" },
		settings = {
			["rust-analyzer"] = {
				diagnostics = { disabled = { "unresolved-proc-macro" } },
				check = { command = vim.fn.executable("cargo-clippy") == 1 and "clippy" or "check" },
			},
		},
	})
end

if vim.fn.executable("clangd") == 1 then
	add_lsp("clangd", {
		cmd = { "clangd", "--offset-encoding=utf-8" },
		filetypes = { "c", "cpp" },
		root_markers = { ".clangd", "compile_commands.json" },
	})
end

if vim.fn.executable("bash-language-server") == 1 then
	add_lsp("bashls", {
		cmd = { "bash-language-server", "start" },
		filetypes = { "sh" },
	})
end

if vim.fn.executable("gopls") == 1 then
	add_lsp("gopls", {
		cmd = { "gopls", "serve" },
		filetypes = { "go", "gomod" },
		settings = {
			["gopls"] = {
				gofumpt = vim.fn.executable("gofumpt") == 1,
				staticcheck = vim.fn.executable("staticcheck") == 1,
			},
		},
	})
end

if vim.fn.executable("pyright-langserver") == 1 then
	add_lsp("pyright", {
		cmd = { "pyright-langserver", "--stdio" },
		filetypes = { "python" },
		root_markers = { "pyproject.toml", "setup.py", "requirements.txt" },
	})
end

if vim.fn.executable("zls") == 1 then
	add_lsp("zls", {
		cmd = { "zls" },
		filetypes = { "zig" },
		root_markers = { "build.zig", "build.zig.zon" },
	})
end

vim.lsp.config("*", { root_markers = { ".git" } })

vim.api.nvim_create_autocmd({ "LspAttach" }, {
	desc = "Set mappings in LSP-enabled buffer",
	group = vim.api.nvim_create_augroup("LspAttach", { clear = true }),
	callback = function()
		vim.opt_local.signcolumn = "yes"

		vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, {
			buffer = true,
			desc = "LSP signature help",
		})

		vim.keymap.set("n", "<C-]>", vim.lsp.buf.definition, {
			buffer = true,
			desc = "LSP definition",
		})
	end,
})

vim.api.nvim_create_user_command("ToggleFormatOnSave", function(opts)
	if pcall(vim.api.nvim_get_autocmds, { group = "FormatOnSave" }) then
		if not opts.bang then
			vim.api.nvim_del_augroup_by_name("FormatOnSave")
		end
	else
		vim.api.nvim_create_autocmd({ "BufWritePre" }, {
			pattern = { "*.zig", "*.nix", "*.go", "*.sh", "*.bash", "*.rs" },
			group = vim.api.nvim_create_augroup("FormatOnSave", { clear = true }),
			callback = function()
				if vim.lsp.buf_is_attached() then
					vim.lsp.buf.format()
				end
			end,
		})
	end
end, {
	bang = true,
	desc = "Toggle format on save for LSP-enabled buffers",
})

-- Enable format on save, initially.
vim.cmd.ToggleFormatOnSave()
