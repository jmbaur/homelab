local lspconfig = require("lspconfig")
local util = require("lspconfig.util")
local null_ls = require("null-ls")
local telescope_builtins = require("telescope.builtin")

local function org_imports()
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

local lsp_formatting_augroup = vim.api.nvim_create_augroup("LspFormatting", {})
local org_imports_augroup = vim.api.nvim_create_augroup("OrgImports", {})

local get_on_attach = function(settings)
	return function(client, bufnr)
		if settings.format and client.supports_method("textDocument/formatting") then
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
		vim.keymap.set("n", "<leader>i", telescope_builtins.lsp_implementations, opts("LSP implementations"))
		vim.keymap.set("n", "<leader>n", vim.lsp.buf.rename, opts("Rename"))
		vim.keymap.set("n", "<leader>r", telescope_builtins.lsp_references, opts("LSP references"))
		vim.keymap.set("n", "K", vim.lsp.buf.hover, opts("Hover"))
		vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts("Go to previous diagnostic"))
		vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts("Go to next diagnostic"))
		vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts("Go to declaration"))
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts("Go to definition"))
	end
end

local on_attach_format_orgimports = get_on_attach({ format = true, org_imports = true })
local on_attach_format = get_on_attach({ format = true, org_imports = false })
local on_attach_orgimports = get_on_attach({ format = false, org_imports = true })
local on_attach = get_on_attach({ format = false, org_imports = false })

local servers = {
	clangd = { required_exe = { "clangd" }, lsp_config = { on_attach = on_attach } },
	gopls = {
		required_exe = { "go", "gopls", "gofumpt", "staticcheck" },
		lsp_config = {
			on_attach = on_attach_format_orgimports,
			settings = { gopls = { gofumpt = true, staticcheck = true } },
		},
	},
	pylsp = {
		required_exe = { "pylsp" },
		lsp_config = {
			on_attach = on_attach_format,
			settings = { pylsp = { plugins = { black = { enabled = true } } } },
		},
	},
	nil_ls = { required_exe = { "nil" }, lsp_config = { on_attach = on_attach } },
	rust_analyzer = {
		required_exe = { "cargo", "rustc", "rust-analyzer" },
		lsp_config = {
			on_attach = on_attach_format,
			settings = {
				["rust-analyzer"] = {
					-- use cargo-clippy on save instead of cargo-check
					checkOnSave = { command = "clippy" },
				},
			},
		},
	},
	sumneko_lua = {
		required_exe = { "lua-language-server" },
		lsp_config = {
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
	tsserver = {
		required_exe = { "tsserver", "typescript-language-server" },
		lsp_config = {
			on_attach = on_attach_orgimports,
			root_dir = util.root_pattern("package.json", "tsconfig.json"),
		},
	},
	zls = { required_exe = { "zls" }, lsp_config = { on_attach = on_attach_format } },
}

for lsp, settings in pairs(servers) do
	local do_setup = true
	if settings.required_exe ~= nil then
		for _, exe in ipairs(settings.required_exe) do
			-- If any required executables for a given language
			-- server are not found, don't setup the LSP.
			if vim.fn.executable(exe) ~= 1 then
				do_setup = false
				break
			end
		end
	else
		do_setup = true
	end
	if do_setup then
		lspconfig[lsp].setup(settings.lsp_config)
	end
end

local conditional_null_ls_sources = {
	-- { required_exe = "ruff",        source = null_ls.builtins.diagnostics.ruff },
	-- { required_exe = "ruff",        source = null_ls.builtins.formatting.ruff },
	{ required_exe = "cue", source = null_ls.builtins.diagnostics.cue_fmt },
	{ required_exe = "cue", source = null_ls.builtins.formatting.cue_fmt },
	{ required_exe = "deno", source = null_ls.builtins.formatting.deno_fmt },
	{ required_exe = "nixpkgs-fmt", source = null_ls.builtins.formatting.nixpkgs_fmt },
	{ required_exe = "shellcheck", source = null_ls.builtins.diagnostics.shellcheck },
	{ required_exe = "shfmt", source = null_ls.builtins.formatting.shfmt },
	{ required_exe = "taplo", source = null_ls.builtins.formatting.taplo },
	{ required_exe = "tidy", source = null_ls.builtins.diagnostics.tidy },
	{ required_exe = "tidy", source = null_ls.builtins.formatting.tidy },
	{ required_exe = "yamlfmt", source = null_ls.builtins.formatting.yamlfmt },
}

local null_ls_sources = {}
for _, source in pairs(conditional_null_ls_sources) do
	-- If the required executable for a given null_ls source is found,
	-- setup the source.
	if vim.fn.executable(source.required_exe) == 1 then
		table.insert(null_ls_sources, source.source)
	end
end
null_ls.setup({ on_attach = on_attach_format, sources = null_ls_sources })

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
	underline = true,
	virtual_text = { spacing = 4 },
	signs = false,
	update_in_insert = false,
})

vim.diagnostic.config({ virtual_text = false })

-- don't use `vim.lsp.formatexpr` for lsp attached buffers
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		vim.bo[args.buf].formatexpr = nil
	end,
})
