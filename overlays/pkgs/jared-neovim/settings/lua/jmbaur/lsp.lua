local lspconfig = require("lspconfig")
local null_ls = require("null-ls")

local left_aligned_line = "\xe2\x96\x8e"

local null_ls_sources = {}
if vim.g.lang_support_lua then
	table.insert(null_ls_sources, null_ls.builtins.formatting.stylua)
end
if vim.g.lang_support_nix then
	table.insert(null_ls_sources, null_ls.builtins.formatting.nixfmt)
end
null_ls.setup({ sources = null_ls_sources })

local toggle_format_on_save = function()
	if not vim.b.format_on_save or vim.b.format_on_save == true then
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

local get_organize_imports = function(client)
	return function()
		if not format_on_save() then
			return
		end

		local params = vim.lsp.util.make_range_params(0, "utf-8")
		params["context"] = { only = { "source.organizeImports" } }
		local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 1000)
		for _, res in pairs(result or {}) do
			for _, r in pairs(res.result or {}) do
				if r.edit then
					vim.lsp.util.apply_workspace_edit(r.edit, "utf-8")
				else
					client:exec_cmd(r.command)
				end
			end
		end
	end
end

local lsp_formatting_augroup = vim.api.nvim_create_augroup("LspFormatting", { clear = true })

vim.api.nvim_create_autocmd("LspDetach", {
	group = lsp_formatting_augroup,
	callback = function(args)
		-- Get the detaching client.
		local client = vim.lsp.get_client_by_id(args.data.client_id)

		if not client then
			return
		end

		-- Remove the autocommand to format the buffer on save, if it exists.
		if client:supports_method("textDocument/formatting") then
			vim.api.nvim_clear_autocmds({
				event = "BufWritePre",
				buffer = args.buf,
			})
		end
	end,
})

local get_on_attach = function(settings)
	local format = settings.format or false
	local null_ls_format = settings.null_ls_format or false
	local organize_imports = settings.organize_imports or false

	return function(client, bufnr)
		-- Always display sign column for LSP enabled windows.
		vim.opt_local.signcolumn = "yes:1"

		vim.api.nvim_clear_autocmds({ group = lsp_formatting_augroup, buffer = bufnr })

		if (format and client:supports_method("textDocument/formatting")) or null_ls_format then
			vim.api.nvim_create_autocmd("BufWritePre", {
				group = lsp_formatting_augroup,
				buffer = bufnr,
				callback = function()
					if not format_on_save() then
						return
					end

					vim.lsp.buf.format({
						-- Make sure there aren't any conflicts between
						-- null_ls and LSP's formatter.
						filter = function(lsp_client)
							if null_ls_format then
								return lsp_client.name == "null-ls"
							else
								return true
							end
						end,
					})
				end,
			})
		end

		if organize_imports and client:supports_method("textDocument/codeAction") then
			vim.api.nvim_create_autocmd("BufWritePre", {
				group = lsp_formatting_augroup,
				buffer = bufnr,
				callback = get_organize_imports(client),
			})
		end

		-- Prevent LSP preview window from opening on omnifunc.
		vim.opt.completeopt:remove({ "preview" })

		vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, keymap_opts(bufnr, "Signature help"))
		vim.keymap.set("n", "<Leader>D", vim.lsp.buf.type_definition, keymap_opts(bufnr, "Type definition"))
		vim.keymap.set("n", "<Leader>a", vim.lsp.buf.code_action, keymap_opts(bufnr, "Code action"))
		vim.keymap.set("n", "<Leader>n", vim.lsp.buf.rename, keymap_opts(bufnr, "Rename"))
		vim.keymap.set("n", "gD", vim.lsp.buf.declaration, keymap_opts(bufnr, "Go to declaration"))
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, keymap_opts(bufnr, "Go to definition"))
	end
end

local on_attach_format_orgimports = get_on_attach({ format = true, organize_imports = true })
local on_attach_format = get_on_attach({ format = true })
local on_attach_format_null_ls = get_on_attach({ format = true, null_ls_format = true })
local on_attach = get_on_attach({})

local servers = {
	bashls = { enable = vim.g.lang_support_shell, config = { on_attach = on_attach_format } },
	clangd = { enable = vim.g.lang_support_c, config = { on_attach = on_attach_format } },
	gopls = {
		enable = vim.g.lang_support_go,
		config = {
			on_attach = on_attach_format_orgimports,
			settings = { gopls = { gofumpt = true, staticcheck = true } },
		},
	},
	nil_ls = { enable = vim.g.lang_support_nix, config = { on_attach = on_attach_format_null_ls } },
	lua_ls = {
		enable = vim.g.lang_support_lua,
		config = {
			on_attach = on_attach_format_null_ls,
			on_init = function(client)
				-- If lua-language-server is configured for a given project,
				-- don't assume it is lua for neovim.
				if client.workspace_folders then
					local path = client.workspace_folders[1].name
					---@diagnostic disable-next-line: undefined-field
					if vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc") then
						return
					end
				end

				client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
					-- Tell the language server which version of Lua you're using
					-- (most likely LuaJIT in the case of Neovim)
					runtime = { version = "LuaJIT" },
					-- Make the server aware of Neovim runtime files
					workspace = {
						checkThirdParty = false,
						library = { vim.env.VIMRUNTIME },
					},
				})
			end,
			settings = { Lua = {} },
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
	nushell = { enable = vim.g.lang_support_nushell, config = { on_attach = on_attach_format } },
	zls = { enable = vim.g.lang_support_zig, config = { on_attach = on_attach_format } },
	rust_analyzer = {
		enable = vim.g.lang_support_rust,
		config = {
			on_attach = on_attach_format,
			settings = {
				["rust-analyzer"] = {
					-- use cargo-clippy if available
					--
					-- TODO(jared): It would be nice to detect this in on_attach
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
	update_in_insert = false,
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

-- local group = vim.api.nvim_create_augroup("DiagnostickQuickfix", { clear = true })

-- local insert_leave_auto_cmds = { "InsertLeave", "CursorHoldI" }
-- vim.api.nvim_create_autocmd(insert_leave_auto_cmds, {
-- 	group = group,
-- 	callback = function()
-- 		local all_errors = vim.diagnostic.get(nil, { severity = vim.diagnostic.severity.ERROR })
--
-- 		if #all_errors > 0 then
-- 			vim.api.nvim_command(string.format("botright copen %d", math.min(#all_errors, 10)))
-- 			vim.api.nvim_command("wincmd p")
-- 		end
-- 	end,
-- })

-- vim.api.nvim_create_autocmd("DiagnosticChanged", {
-- 	group = group,
-- 	callback = function(event)
-- 		local all_errors = vim.tbl_filter(function(diagnostic)
-- 			return diagnostic.severity == vim.diagnostic.severity.ERROR
-- 		end, event.data.diagnostics)
--
-- 		vim.fn.setqflist({}, " ", { title = "Errors", items = vim.diagnostic.toqflist(all_errors) })
--
-- 		if #all_errors == 0 then
-- 			vim.api.nvim_command("cclose")
-- 		end
-- 	end,
-- })

-- Don't use `vim.lsp.formatexpr` for lsp attached buffers. This allows
-- for reflowing comments with 'gq'.
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		vim.bo[args.buf].formatexpr = nil
	end,
})

vim.api.nvim_create_user_command("ToggleFormatOnSave", toggle_format_on_save, { desc = "Toggle format on save" })
