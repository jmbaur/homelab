local lspconfig = require("lspconfig")

local M = {}

local conditional_efm_languages = {
	sh = {
		{ enable = vim.g.lang_support_shell, config = require("efmls-configs.formatters.shfmt") },
		{ enable = vim.g.lang_support_shell, config = require("efmls-configs.linters.shellcheck") },
	},
	nix = { {
		enable = vim.g.lang_support_nix, config = { formatCommand = "nixpkgs-fmt", formatStdin = true },
	} },
	toml = { { enable = vim.g.lang_support_nix, config = require("efmls-configs.formatters.taplo") } },
	latex = { {
		enable = vim.g.lang_support_latex, config = require("efmls-configs.formatters.latexindent")
	} },
}

local toggle_format_on_save = function()
	local ignoring_buf_write_pre = false

	for _, event in pairs(vim.opt.eventignore:get()) do
		if event == "BufWritePre" then
			ignoring_buf_write_pre = true
		end
	end

	if ignoring_buf_write_pre then
		vim.opt.eventignore:remove({ "BufWritePre" })
		vim.print("enabled format on save")
	else
		vim.opt.eventignore:append({ "BufWritePre" })
		vim.print("disabled format on save")
	end
end

M.setup = function(config)
	local lsp_implementations = config.launcher.lsp_implementations
	local lsp_references = config.launcher.lsp_references

	local org_imports = function()
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
			if settings.format and client.supports_method("textDocument/formatting") then
				local lsp_formatting_augroup = vim.api.nvim_create_augroup("LspFormatting", {})
				vim.api.nvim_clear_autocmds({ group = lsp_formatting_augroup, buffer = bufnr })
				vim.api.nvim_create_autocmd("BufWritePre", {
					group = lsp_formatting_augroup,
					buffer = bufnr,
					callback = function()
						vim.lsp.buf.format()
					end,
				})
			else
				client.server_capabilities.documentFormattingProvider = false
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

			local opts = function(desc)
				return { buffer = bufnr, desc = desc }
			end
			vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts("Signature help"))
			vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, opts("Type definition"))
			vim.keymap.set("n", "<leader>a", vim.lsp.buf.code_action, opts("Code action"))
			vim.keymap.set("n", "<leader>i", lsp_implementations, opts("LSP implementations"))
			vim.keymap.set("n", "<leader>n", vim.lsp.buf.rename, opts("Rename"))
			vim.keymap.set("n", "<leader>r", lsp_references, opts("LSP references"))
			vim.keymap.set("n", "K", vim.lsp.buf.hover, opts("Hover"))
			vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts("Go to previous diagnostic"))
			vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts("Go to next diagnostic"))
			vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts("Go to declaration"))
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts("Go to definition"))
		end
	end

	local on_attach_format_orgimports = get_on_attach({ format = true, org_imports = true })
	local on_attach_format = get_on_attach({ format = true, org_imports = false })
	local on_attach = get_on_attach({ format = false, org_imports = false })

	local efm_languages = {}
	for lang, lang_config in pairs(conditional_efm_languages) do
		local lang_efm_config = {}
		for _, tool in pairs(lang_config) do
			if tool.enable then
				table.insert(lang_efm_config, tool.config)
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
		pylsp = {
			enable = vim.g.lang_support_python,
			config = {
				on_attach = on_attach_format,
				settings = { pylsp = { plugins = { black = { enabled = true } } } },
			},
		},
		nil_ls = { enable = vim.g.lang_support_nix, config = { on_attach = on_attach } },
		rust_analyzer = {
			enable = vim.g.lang_support_rust,
			config = {
				on_attach = on_attach_format,
				settings = {
					["rust-analyzer"] = {
						-- use cargo-clippy on save instead of cargo-check
						check = { command = vim.fn.executable("cargo-clippy") == 1 and "clippy" or "check" },
					},
				},
			},
		},
		lua_ls = {
			enable = vim.g.lang_support_lua,
			config = {
				on_attach = on_attach_format,
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
		zls = { enable = vim.g.lang_support_zig, config = { on_attach = on_attach_format } },
	}

	for lsp, settings in pairs(servers) do
		if settings.enable then
			lspconfig[lsp].setup(settings.config)
		end
	end

	vim.diagnostic.config({
		underline = true,
		virtual_text = false,
		signs = false,
	})

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
	vim.keymap.set("n", "<leader>t", toggle_format_on_save, { desc = "Toggle format on save" })
end

return M
