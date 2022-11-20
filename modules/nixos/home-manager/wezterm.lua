local wezterm = require("wezterm")

local mouse_bindings = {
	{
		event = { Down = { streak = 1, button = "Left" } },
		mods = "CTRL|SHIFT",
		action = wezterm.action.SelectTextAtMouseCursor("Block"),
	},
	{
		event = { Drag = { streak = 1, button = "Left" } },
		mods = "CTRL|SHIFT",
		action = wezterm.action.ExtendSelectionToMouseCursor("Block"),
	},
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CTRL|SHIFT",
		action = wezterm.action.CompleteSelection("ClipboardAndPrimarySelection"),
	},
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CTRL",
		action = wezterm.action.OpenLinkAtMouseCursor,
	},
}

for streak in ipairs({ 1, 2, 3 }) do
	table.insert(mouse_bindings, {
		event = { Up = { streak = streak, button = "Left" } },
		mods = "NONE",
		action = wezterm.action.CompleteSelection("ClipboardAndPrimarySelection"),
	})
end

return {
	color_scheme = "Builtin Dark",
	font = wezterm.font("JetBrains Mono"),
	font_size = 16.0,
	hide_tab_bar_if_only_one_tab = true,
	mouse_bindings = mouse_bindings,
	use_fancy_tab_bar = false,
	window_padding = { left = 0, right = 0, top = 0, bottom = 0 },
}
