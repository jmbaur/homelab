local snippets = require("mini.snippets")

snippets.setup({
	snippets = {
		{ prefix = "todo", body = "TODO(jared): " },
		{ prefix = "date", body = "$CURRENT_YEAR-$CURRENT_MONTH-$CURRENT_DATE" },
		snippets.gen_loader.from_lang(),
	},
})
