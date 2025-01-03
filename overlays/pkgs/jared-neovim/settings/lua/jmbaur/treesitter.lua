local treesitter_configs = require("nvim-treesitter.configs")
local treesitter_context = require("treesitter-context")

treesitter_context.setup({ max_lines = 3 })

treesitter_configs.setup({
	auto_install = false,
	modules = {},
	ignore_install = {},
	ensure_installed = {},
	sync_install = false,
	highlight = {
		enable = true,
		additional_vim_regex_highlighting = false,
	},
	refactor = {
		highlight_current_scope = { enable = false },
		smart_rename = {
			enable = true,
			keymaps = { smart_rename = "grr" },
		},
		navigation = {
			enable = true,
			keymaps = {
				goto_definition = "gnd",
				list_definitions = "gnD",
				list_definitions_toc = "gO",
				goto_next_usage = "<a-*>",
				goto_previous_usage = "<a-#>",
			},
		},
	},
	indent = { enable = true },
	textobjects = {
		select = {
			enable = true,
			lookahead = true,
			keymaps = {
				["ab"] = "@block.outer",
				["ib"] = "@block.inner",
				["ac"] = "@class.outer",
				["ic"] = "@class.inner",
				["af"] = "@function.outer",
				["if"] = "@function.inner",
			},
		},
	},
	incremental_selection = {
		enable = true,
		keymaps = {
			init_selection = "gnn",
			node_incremental = "grn",
			scope_incremental = "grc",
			node_decremental = "grm",
		},
	},
})
