local lspconfig = require("lspconfig")

local left_aligned_line = "\xe2\x96\x8e"

local conditional_efm_languages = {
	nix = {
		enable = vim.g.lang_support_nix,
		tools = { { formatCommand = "nixfmt", formatStdin = true } },
	},
	sh = {
		enable = vim.g.lang_support_shell,
		tools = {
			require("efmls-configs.formatters.shfmt"),
			require("efmls-configs.linters.shellcheck"),
		},
	},
	toml = {
		enable = vim.g.lang_support_toml,
		tools = { require("efmls-configs.formatters.taplo") },
	},
	latex = {
		enable = vim.g.lang_support_latex,
		tools = { { formatCommand = "tex-fmt --stdin", formatStdin = true } },
	},
	lua = {
		enable = vim.g.lang_support_lua,
		tools = { require("efmls-configs.formatters.stylua") },
	},
}

local toggle_format_on_save = function()
	if vim.b.format_on_save == nil or vim.b.format_on_save == true then
		vim.print("disabled format on save for current buffer")
		vim.b.format_on_save = false
	else
		vim.print("enabled format on save for current buffer")
		vim.b.format_on_save = true
	end
end

local format_on_save = function()
	for _, val in pairs({ vim.b.format_on_save, vim.g.format_on_save }) do
		if val == false then
			return false
		end
	end

	return true
end

local keymap_opts = function(bufnr, desc)
	return { buffer = bufnr, desc = desc }
end

local org_imports = function()
	if not (format_on_save()) then
		return
	end

	local params = vim.lsp.util.make_range_params()
	params.context = { only = { "source.organizeImports" } }
	local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 1000)
	for _, res in pairs(result or {}) do
		for _, r in pairs(res.result or {}) do
			if r.edit then
				vim.lsp.util.apply_workspace_edit(r.edit, "UTF-8")
			else
				vim.lsp.buf.execute_command(r.command)
			end
		end
	end
end

local get_on_attach = function(settings)
	return function(client, bufnr)
		vim.wo.signcolumn = "yes:1" -- always display sign column for LSP enabled windows

		if settings.format and client.supports_method("textDocument/formatting") then
			local lsp_formatting_augroup = vim.api.nvim_create_augroup("LspFormatting", {})
			vim.api.nvim_clear_autocmds({ group = lsp_formatting_augroup, buffer = bufnr })
			vim.api.nvim_create_autocmd("BufWritePre", {
				group = lsp_formatting_augroup,
				buffer = bufnr,
				callback = function()
					if format_on_save() then
						vim.lsp.buf.format()
					end
				end,
			})
		end

		if settings.org_imports and client.supports_method("textDocument/codeAction") then
			local org_imports_augroup = vim.api.nvim_create_augroup("OrgImports", {})
			vim.api.nvim_clear_autocmds({ group = org_imports_augroup, buffer = bufnr })
			vim.api.nvim_create_autocmd("BufWritePre", {
				group = org_imports_augroup,
				buffer = bufnr,
				callback = org_imports,
			})
		end

		-- Prevent LSP preview window from opening on omnifunc
		vim.opt.completeopt:remove({ "preview" })

		vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, keymap_opts(bufnr, "Signature help"))
		vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, keymap_opts(bufnr, "Type definition"))
		vim.keymap.set("n", "<leader>a", vim.lsp.buf.code_action, keymap_opts(bufnr, "Code action"))
		vim.keymap.set("n", "<leader>n", vim.lsp.buf.rename, keymap_opts(bufnr, "Rename"))
		vim.keymap.set("n", "gD", vim.lsp.buf.declaration, keymap_opts(bufnr, "Go to declaration"))
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, keymap_opts(bufnr, "Go to definition"))
	end
end

local on_attach_format_orgimports = get_on_attach({ format = true, org_imports = true })
local on_attach_format = get_on_attach({ format = true, org_imports = false })
local on_attach = get_on_attach({ format = false, org_imports = false })

local efm_languages = {}
local efm_filetypes = {}
for lang, lang_config in pairs(conditional_efm_languages) do
	local lang_efm_config = {}
	if lang_config.enable then
		table.insert(efm_filetypes, lang)
		for _, tool in pairs(lang_config.tools) do
			table.insert(lang_efm_config, tool)
		end
	end
	efm_languages[lang] = lang_efm_config
end

local servers = {
	clangd = { enable = vim.g.lang_support_c, config = { on_attach = on_attach_format } },
	efm = {
		enable = true,
		config = {
			on_attach = on_attach_format,
			init_options = { documentFormatting = true },
			settings = {
				rootMarkers = { ".git/" },
				languages = efm_languages,
			},
			filetypes = efm_filetypes,
		},
	},
	hls = {
		enable = vim.g.lang_support_haskell,
		config = { on_attach = on_attach_format },
	},
	gopls = {
		enable = vim.g.lang_support_go,
		config = {
			on_attach = on_attach_format_orgimports,
			settings = { gopls = { gofumpt = true, staticcheck = true } },
		},
	},
	nil_ls = { enable = vim.g.lang_support_nix, config = { on_attach = on_attach } },
	lua_ls = {
		enable = vim.g.lang_support_lua,
		config = {
			on_attach = on_attach,
			settings = {
				Lua = {
					runtime = { version = "LuaJIT" },
					diagnostics = { globals = { "vim" } },
					workspace = { library = vim.api.nvim_get_runtime_file("", true), checkThirdParty = false },
					telemetry = { enable = false },
				},
			},
		},
	},
	pyright = {
		enable = vim.g.lang_support_python,
		config = { on_attach = on_attach },
	},
	ruff = {
		enable = vim.g.lang_support_python,
		config = { on_attach = on_attach_format },
	},
	yamlls = { enable = vim.g.lang_support_yaml, config = { on_attach = on_attach_format } },
	zls = { enable = vim.g.lang_support_zig, config = { on_attach = on_attach_format } },
	rust_analyzer = {
		enable = vim.g.lang_support_rust,
		config = {
			on_attach = on_attach_format,
			settings = {
				["rust-analyzer"] = {
					-- use cargo-clippy if available
					check = { command = vim.fn.executable("cargo-clippy") == 1 and "clippy" or "check" },
				},
			},
		},
	},
}

for lsp, settings in pairs(servers) do
	if settings.enable then
		lspconfig[lsp].setup(settings.config)
	end
end

vim.diagnostic.config({
	severity_sort = true,
	signs = true,
	underline = true,
	virtual_text = false,
})

local sign_symbol = function(name, icon)
	vim.fn.sign_define("DiagnosticSign" .. name, { text = icon, texthl = "DiagnosticSign" .. name })
end
sign_symbol("Error", left_aligned_line)
sign_symbol("Hint", left_aligned_line)
sign_symbol("Info", left_aligned_line)
sign_symbol("Ok", left_aligned_line)
sign_symbol("Warn", left_aligned_line)

vim.api.nvim_create_autocmd("DiagnosticChanged", {
	callback = function(args)
		if #args.data.diagnostics > 0 then
			vim.diagnostic.setqflist({ open = false })
		end
	end,
})

-- don't use `vim.lsp.formatexpr` for lsp attached buffers
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		vim.bo[args.buf].formatexpr = nil
	end,
})

vim.api.nvim_create_user_command("ToggleFormatOnSave", toggle_format_on_save, { desc = "Toggle format on save" })
