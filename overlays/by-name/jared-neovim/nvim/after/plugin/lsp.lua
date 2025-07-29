local add_lsp = function(name, opts)
	vim.lsp.config(name, opts)
	vim.lsp.enable(name)
end

if vim.fn.executable("nil") == 1 then
	add_lsp("nil_ls", {
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
		settings = {
			["rust-analyzer"] = {
				diagnostics = { disabled = { "unresolved-proc-macro" } },
				check = { command = vim.fn.executable("cargo-clippy") == 1 and "clippy" or "check" },
			},
		},
	})
end

if vim.fn.executable("clangd") == 1 then
	add_lsp("clangd", {})
end

if vim.fn.executable("dts-lsp") == 1 then
	add_lsp("dts_lsp", {})
end

if vim.fn.executable("bash-language-server") == 1 then
	add_lsp("bashls", {})
end

if vim.fn.executable("gopls") == 1 then
	add_lsp("gopls", {
		settings = {
			gopls = {
				gofumpt = vim.fn.executable("gofumpt") == 1,
				staticcheck = vim.fn.executable("staticcheck") == 1,
			},
		},
	})
end

if vim.fn.executable("lua-language-server") == 1 then
	add_lsp("lua_ls", {
		on_init = function(client)
			-- TODO(jared): detect if we are in a neovim lua file
			--
			-- if client.workspace_folders then
			-- 	local path = client.workspace_folders[1].name
			-- 	if
			-- 		path ~= vim.fn.stdpath("config")
			-- 		and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
			-- 	then
			-- 		return
			-- 	end
			-- end

			client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
				runtime = {
					-- Tell the language server which version of Lua you're using (most
					-- likely LuaJIT in the case of Neovim)
					version = "LuaJIT",
					-- Tell the language server how to find Lua modules same way as Neovim
					-- (see `:h lua-module-load`)
					path = {
						"lua/?.lua",
						"lua/?/init.lua",
					},
				},
				-- Make the server aware of Neovim runtime files
				workspace = {
					checkThirdParty = false,
					library = {
						vim.env.VIMRUNTIME,
						-- Depending on the usage, you might want to add additional paths
						-- here.
						-- '${3rd}/luv/library'
						-- '${3rd}/busted/library'
					},
					-- Or pull in all of 'runtimepath'.
					-- NOTE: this is a lot slower and will cause issues when working on
					-- your own configuration.
					-- See https://github.com/neovim/nvim-lspconfig/issues/3189
					-- library = {
					--   vim.api.nvim_get_runtime_file('', true),
					-- }
				},
			})
		end,
		settings = { Lua = {} },
	})
end

if vim.fn.executable("pyright-langserver") == 1 then
	add_lsp("pyright", {})
end

if vim.fn.executable("zls") == 1 then
	add_lsp("zls", {
		settings = { zls = { semantic_tokens = "partial" } },
	})
end

vim.lsp.config("*", { root_markers = { ".git" } })

vim.api.nvim_create_autocmd({ "LspAttach" }, {
	desc = "Set mappings in LSP-enabled buffer",
	group = vim.api.nvim_create_augroup("LspAttach", { clear = true }),
	callback = function(opts)
		vim.opt_local.signcolumn = "yes"

		if vim.tbl_contains({ "zig", "nix", "go", "sh", "bash", "rust" }, vim.fn.getbufvar(opts.buf, "&filetype")) then
			vim.api.nvim_create_autocmd({ "BufWritePre" }, {
				group = vim.api.nvim_create_augroup("FormatOnSave", { clear = true }),
				buffer = opts.buf,
				callback = function()
					if not vim.lsp.buf_is_attached(0) then
						return
					end

					if vim.g.no_format_on_save then
						return
					end

					vim.lsp.buf.format()
				end,
			})
		end
	end,
})

vim.api.nvim_create_user_command("ToggleFormatOnSave", function(opts)
	if opts.bang or vim.g.no_format_on_save then
		vim.g.no_format_on_save = nil
	else
		vim.g.no_format_on_save = true
	end
end, {
	bang = true, -- forcefully enable format on save
	desc = "Toggle format on save for LSP-enabled buffers",
})

vim.diagnostic.config({
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "\u{2759}",
			[vim.diagnostic.severity.WARN] = "\u{2759}",
			[vim.diagnostic.severity.INFO] = "\u{2759}",
			[vim.diagnostic.severity.HINT] = "\u{2759}",
		},
	},
})
